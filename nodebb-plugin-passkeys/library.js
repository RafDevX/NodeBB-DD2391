'use strict';

const { Fido2Lib } = require('fido2-lib');
const base64url = require('base64url');

const db = require.main.require('./src/database');
const nconf = require.main.require('nconf');
const async = require.main.require('async');
const user = require.main.require('./src/user');
const meta = require.main.require('./src/meta');
const groups = require.main.require('./src/groups');
const plugins = require.main.require('./src/plugins');
const notifications = require.main.require('./src/notifications');
const utils = require.main.require('./src/utils');
const translator = require.main.require('./src/translator');
const routeHelpers = require.main.require('./src/routes/helpers');
const controllerHelpers = require.main.require('./src/controllers/helpers');
const SocketPlugins = require.main.require('./src/socket.io/plugins');

const atob = (base64str) => Buffer.from(base64str, 'base64').toString('binary');

const AUTHENTICATOR_SELECTION = {
    // authenticatorAttachment: 'platform',
    userVerification: 'prefered',
    residentKey: 'required',
    requireResidentKey: true,
};

const plugin = {
    _f2l: undefined,
};

plugin.init = async (params) => {
    const { router } = params;
    const hostMiddleware = params.middleware;
    const accountMiddlewares = [
        hostMiddleware.exposeUid,
        hostMiddleware.ensureLoggedIn,
        hostMiddleware.canViewUsers,
        hostMiddleware.checkAccountPermissions,
        hostMiddleware.buildAccountData,
    ];
    const hostHelpers = require.main.require('./src/routes/helpers');
    const controllers = require('./lib/controllers');

    // ACP
    hostHelpers.setupAdminPageRoute(
        router,
        '/admin/plugins/passkeys',
        [hostMiddleware.pluginHooks],
        controllers.renderAdminPage
    );

    // UCP
    hostHelpers.setupPageRoute(
        router,
        '/user/:userslug/passkeys',
        accountMiddlewares,
        controllers.renderSettings
    );

    // 2fa Login
    // hostHelpers.setupPageRoute(router, '/login/passkeys', [hostMiddleware.ensureLoggedIn], controllers.renderChoices);

    // Websockets
    // SocketPlugins['passkeys'] = require('./websockets');

    // Fido2Lib instantiation
    // https://www.passkeys.com/guides
    plugin._f2l = new Fido2Lib({
        timeout: 60 * 1000, // 60 seconds
        rpId: nconf.get('url_parsed').hostname,
        rpName: meta.config.title || 'NodeBB',
        authenticatorSelection: AUTHENTICATOR_SELECTION,
        cryptoParams: [-7, -35, -36, -257, -258, -259, -37, -38, -39, -8],
        attestation: 'none',
    });

    // Configure passkeys path exemptions
    let prefixes = ['/reset', '/confirm'];
    let pages = ['/login/passkeys', '/register/complete'];
    let paths = ['/api/v3/plugins/passkeys/verify'];
    ({ prefixes, pages, paths } = await plugins.hooks.fire(
        'filter:passkeys.exemptions',
        { prefixes, pages, paths }
    ));
    pages = pages.reduce((memo, cur) => {
        memo.push(nconf.get('relative_path') + cur);
        memo.push(`${nconf.get('relative_path')}/api${cur}`);
        return memo;
    }, []);
    plugin.exemptions = {
        prefixes,
        paths: new Set(pages.concat(paths)),
    };
};

plugin.addRoutes = async ({ router, middleware, helpers }) => {
    const middlewares = [middleware.ensureLoggedIn];

    routeHelpers.setupApiRoute(
        router,
        'get',
        '/passkeys/register',
        middlewares,
        async (req, res) => {
            const registrationRequest = await plugin._f2l.attestationOptions();
            const userData = await user.getUserFields(req.uid, [
                'username',
                'displayname',
            ]);
            registrationRequest.user = {
                id: base64url(String(req.uid)),
                name: userData.username,
                displayName: userData.displayname,
            };
            registrationRequest.challenge = base64url(
                registrationRequest.challenge
            );
            req.session.registrationRequest = registrationRequest;
            registrationRequest.authenticatorSelection =
                AUTHENTICATOR_SELECTION;
            helpers.formatApiResponse(200, res, registrationRequest);
        }
    );

    routeHelpers.setupApiRoute(
        router,
        'post',
        '/passkeys/register',
        middlewares,
        async (req, res) => {
            const attestationExpectations = {
                challenge: req.session.registrationRequest.challenge,
                origin: `${nconf.get('url_parsed').protocol}//${
                    nconf.get('url_parsed').host
                }`,
                factor: 'second',
            };
            req.body.rawId = Uint8Array.from(
                atob(base64url.toBase64(req.body.rawId)),
                (c) => c.charCodeAt(0)
            ).buffer;
            const regResult = await plugin._f2l.attestationResult(
                req.body,
                attestationExpectations
            );
            plugin.saveAuthn(req.uid, regResult.authnrData);
            delete req.session.registrationRequest;
            req.session.tfa = true; // eliminate re-challenge on registration

            helpers.formatApiResponse(200, res);
        }
    );

    // Note: auth request generated in Controllers.renderLogin
    routeHelpers.setupApiRoute(
        router,
        'post',
        '/passkeys/verify',
        middlewares,
        async (req, res) => {
            const prevCounter = await plugin.getAuthnCount(
                req.body.authResponse.id
            );
            const publicKey = await plugin.getAuthnPublicKey(
                req.uid,
                req.body.authResponse.id
            );
            const expectations = {
                challenge: req.session.authRequest,
                origin: `${nconf.get('url_parsed').protocol}//${
                    nconf.get('url_parsed').host
                }`,
                factor: 'second',
                publicKey,
                prevCounter,
                userHandle: null,
            };

            req.body.authResponse.rawId = Uint8Array.from(
                atob(base64url.toBase64(req.body.authResponse.rawId)),
                (c) => c.charCodeAt(0)
            ).buffer;
            req.body.authResponse.response.userHandle = undefined;

            const authnResult = await plugin._f2l.assertionResult(
                req.body.authResponse,
                expectations
            );
            const count = authnResult.authnrData.get('counter');
            await plugin.updateAuthnCount(req.body.authResponse.id, count);

            req.session.tfa = true;
            delete req.session.authRequest;
            delete req.session.tfaForce;
            req.session.meta.datetime = Date.now();

            helpers.formatApiResponse(200, res, {
                next: req.query.next || '/',
            });
        }
    );

    routeHelpers.setupApiRoute(
        router,
        'delete',
        '/passkeys',
        middlewares,
        async (req, res) => {
            const { uid } = req;
            const keyIds = await db.getObjectKeys(`passkeys:webauthn:${uid}`);
            await db.sortedSetRemove('passkeys:webauthn:counters', keyIds);
            await db.delete(`passkeys:webauthn:${uid}`);

            helpers.formatApiResponse(200, res);
        }
    );
};

plugin.addAdminNavigation = function (header, callback) {
    translator.translate('[[passkeys:title]]', (title) => {
        header.plugins.push({
            route: '/plugins/passkeys',
            icon: 'fa-lock',
            name: title,
        });

        callback(null, header);
    });
};

plugin.addProfileItem = function (data, callback) {
    translator.translate('[[passkeys:title]]', (title) => {
        data.links.push({
            id: 'passkeys',
            route: 'passkeys',
            icon: 'fa-lock',
            name: title,
            visibility: {
                self: true,
                other: false,
                moderator: false,
                globalMod: false,
                admin: false,
            },
        });

        callback(null, data);
    });
};

plugin.get = async (uid) => db.getObjectField('passkeys:uid:key', uid);

plugin.getAuthnKeyIds = async (uid) => {
    const keys = await db.getObject(`passkeys:webauthn:${uid}`);
    return Object.keys(keys);
};

plugin.getAuthnPublicKey = async (uid, id) =>
    db.getObjectField(`passkeys:webauthn:${uid}`, id);

plugin.getAuthnCount = async (id) =>
    db.sortedSetScore(`passkeys:webauthn:counters`, id);

plugin.updateAuthnCount = async (id, count) =>
    db.sortedSetAdd(`passkeys:webauthn:counters`, count, id);

plugin.save = function (uid, key, callback) {
    db.setObjectField('passkeys:uid:key', uid, key, callback);
};

plugin.saveAuthn = (uid, authnrData) => {
    const counter = authnrData.get('counter');
    const publicKey = authnrData.get('credentialPublicKeyPem');
    const id = base64url(authnrData.get('credId'));
    db.setObjectField(`passkeys:webauthn:${uid}`, id, publicKey);
    db.sortedSetAdd(`passkeys:webauthn:counters`, counter, id);
};

plugin.hasPasskey = async (uid) => db.exists(`passkeys:webauthn:${uid}`);

plugin.disassociate = async (uid) => {
    // Clear U2F keys
    const keyIds = await db.getObjectKeys(`passkeys:webauthn:${uid}`);
    await db.sortedSetRemove('passkeys:webauthn:counters', keyIds);
    await db.delete(`passkeys:webauthn:${uid}`);
};

plugin.overrideUid = async ({ req, locals }) => {
    if (req.uid && (await plugin.hasKey(req.uid)) && req.session.tfa !== true) {
        locals['passkeys'] = req.uid;
        req.uid = 0;
        delete req.user;
        delete req.loggedIn;
    }

    return { req, locals };
};

plugin.check = async ({ req, res }) => {
    if (!req.user || req.session.tfa === true) {
        return;
    }

    const requestPath = req.baseUrl + req.path;
    if (
        plugin.exemptions.paths.has(requestPath) ||
        plugin.exemptions.prefixes.some((prefix) =>
            requestPath.startsWith(nconf.get('relative_path') + prefix)
        )
    ) {
        return;
    }

    let { tfaEnforcedGroups } = await meta.settings.get('passkeys');
    tfaEnforcedGroups = JSON.parse(tfaEnforcedGroups || '[]');

    const redirect = requestPath
        .replace('/api', '')
        .replace(nconf.get('relative_path'), '');

    if (await plugin.hasKey(req.user.uid)) {
        if (!res.locals.isAPI) {
            // Account has TFA, redirect to login
            controllerHelpers.redirect(res, `/login/passkeys?next=${redirect}`);
        } else {
            await controllerHelpers.formatApiResponse(
                401,
                res,
                new Error('[[passkeys:passkey-required]]')
            );
        }
    } else if (
        tfaEnforcedGroups.length &&
        (await groups.isMemberOfGroups(req.uid, tfaEnforcedGroups)).includes(
            true
        )
    ) {
        if (
            req.url.startsWith('/admin') ||
            (!req.url.startsWith('/admin') && !req.url.match('passkeys'))
        ) {
            controllerHelpers.redirect(res, `/me/passkeys?next=${redirect}`);
        }
    }

    // No TFA setup
};

plugin.checkSocket = async (data) => {
    if (!data.socket.uid || data.req.session.tfa === true) {
        return;
    }

    if (await plugin.hasKey(data.socket.uid)) {
        throw new Error('[[passkeys:passkey-required]]');
    }
};

plugin.clearSession = function (data, callback) {
    if (data.req.session) {
        delete data.req.session.tfa;
    }

    setImmediate(callback);
};

plugin.getUsers = function (callback) {
    async.waterfall(
        [
            async.apply(db.getObjectKeys, 'passkey:uid:key'),
            function (uids, next) {
                user.getUsersFields(
                    uids,
                    ['username', 'userslug', 'picture'],
                    next
                );
            },
        ],
        callback
    );
};

plugin.adjustRelogin = async ({ req, res }) => {
    if (await plugin.hasKey(req.uid)) {
        req.session.forceLogin = 0;
        req.session.tfaForce = 1;
        controllerHelpers.redirect(
            res,
            `/login/passkeys?next=${req.session.returnTo}`
        );
    }
};

plugin.integrations = {};

plugin.integrations.writeApi = async (data) => {
    const routeTest = /^\/api\/v\d\/users\/\d+\/tokens\/?/;
    const uidMatch = data.route.match(/(\d+)\/tokens$/);
    const uid = uidMatch ? parseInt(uidMatch[1], 10) : 0;

    // Enforce 2FA on token generation route
    if (
        data.method === 'POST' &&
        routeTest.test(data.route) &&
        (await plugin.hasTotp(uid))
    ) {
        if (!data.req.headers.hasOwnProperty('x-two-factor-authentication')) {
            // No 2FA received
            return data.res
                .status(400)
                .json(
                    data.errorHandler.generate(
                        400,
                        '2fa-enabled',
                        'Two Factor Authentication is enabled for this route, please send in the appropriate additional header for authorization',
                        ['x-two-factor-authentication']
                    )
                );
        }

        const skew = notp.totp.verify(
            data.req.headers['x-two-factor-authentication'],
            await plugin.get(uid)
        );
        if (!skew || Math.abs(skew.delta) > 2) {
            return data.res
                .status(400)
                .json(
                    data.errorHandler.generate(
                        401,
                        '2fa-failed',
                        'The Two-Factor Authentication code provided is not correct or has expired'
                    )
                );
        }
    }
};

module.exports = plugin;
