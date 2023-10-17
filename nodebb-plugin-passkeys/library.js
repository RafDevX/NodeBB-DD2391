'use strict';

const { Fido2Lib } = require('fido2-lib');

const db = require.main.require('./src/database');
const nconf = require.main.require('nconf');
const passport = require.main.require('passport');
const user = require.main.require('./src/user');
const meta = require.main.require('./src/meta');
const groups = require.main.require('./src/groups');
const plugins = require.main.require('./src/plugins');
const translator = require.main.require('./src/translator');
const routeHelpers = require.main.require('./src/routes/helpers');
const controllerHelpers = require.main.require('./src/controllers/helpers');

const PasskeyStrategy = require('./lib/strategy');

const b64uEncode = (s) => Buffer.from(s, 'binary').toString('base64url');
const b64uDecode = (b) => Buffer.from(b, 'base64url').toString('binary');

const origin =
    nconf.get('url_parsed').protocol + '//' + nconf.get('url_parsed').host;

const AUTHENTICATOR_SELECTION = {
    userVerification: 'required',
    residentKey: 'required',
    requireResidentKey: true,
};

const plugin = {
    _f2l: undefined,
};

// ----- //
// Hooks //
// ----- //

plugin.init = async ({ router, middleware }) => {
    const controllers = require('./lib/controllers');
    const accountMiddlewares = [
        middleware.exposeUid,
        middleware.ensureLoggedIn,
        middleware.canViewUsers,
        middleware.checkAccountPermissions,
        middleware.buildAccountData,
    ];

    // ACP
    routeHelpers.setupAdminPageRoute(
        router,
        '/admin/plugins/passkeys',
        [middleware.pluginHooks],
        controllers.renderAdminPage
    );

    // UCP
    routeHelpers.setupPageRoute(
        router,
        '/user/:userslug/passkeys',
        accountMiddlewares,
        controllers.renderSettingsPage
    );

    routeHelpers.setupPageRoute(
        router,
        '/login/passkey',
        [middleware.pluginHooks],
        controllers.renderLoginPage
    );

    // Fido2Lib instantiation
    // https://www.passkeys.com/guides
    plugin._f2l = new Fido2Lib({
        timeout: 60 * 1000, // 60 seconds
        rpId: nconf.get('url_parsed').hostname,
        rpName: meta.config.title || 'NodeBB',
        authenticatorSelection: AUTHENTICATOR_SELECTION,
        // https://www.iana.org/assignments/cose/cose.xhtml
        cryptoParams: [-36, -35, -7, -39, -38, -37, -259, -258, -257],
        attestation: 'none',
    });

    // Configure passkeys path exemptions
    let prefixes = ['/reset', '/confirm'];
    let pages = ['/login/passkey', '/register/complete'];
    let paths = ['/api/v3/plugins/passkeys/register', '/auth/passkey'];
    ({ prefixes, pages, paths } = await plugins.hooks.fire(
        'filter:passkeys.exemptions',
        { prefixes, pages, paths }
    ));
    pages = pages.flatMap((page) => [
        nconf.get('relative_path') + page,
        nconf.get('relative_path') + '/api' + page,
    ]);
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
                id: b64uEncode(String(req.uid)),
                name: userData.username,
                displayName: userData.displayname,
            };
            registrationRequest.challenge = b64uEncode(
                registrationRequest.challenge
            );
            registrationRequest.authenticatorSelection =
                AUTHENTICATOR_SELECTION;
            req.session.passkeysRegistrationRequest = registrationRequest;

            helpers.formatApiResponse(200, res, registrationRequest);
        }
    );

    routeHelpers.setupApiRoute(
        router,
        'post',
        '/passkeys/register',
        middlewares,
        async (req, res) => {
            try {
                const attestationExpectations = {
                    challenge:
                        req.session.passkeysRegistrationRequest.challenge,
                    origin,
                    factor: 'first',
                };

                req.body.rawId = Uint8Array.from(
                    b64uDecode(req.body.rawId),
                    (c) => c.charCodeAt(0)
                ).buffer;
                const regResult = await plugin._f2l.attestationResult(
                    req.body,
                    attestationExpectations
                );
                plugin.saveAuthn(req.uid, regResult.authnrData);
                delete req.session.passkeysRegistrationRequest;

                helpers.formatApiResponse(200, res);
            } catch (e) {
                console.error(e);
                helpers.formatApiResponse(500, res);
            }
        }
    );

    routeHelpers.setupApiRoute(
        router,
        'delete',
        '/passkeys',
        middlewares,
        async (req, res) => {
            await plugin.clearAllKeys(req.uid);
            helpers.formatApiResponse(200, res);
        }
    );

    routeHelpers.setupApiRoute(
        router,
        'post',
        '/passkeys/pwdless-enforced-groups',
        [...middlewares, middleware.admin.checkPrivileges],
        async (req, res) => {
            if (
                !Array.isArray(req.body) ||
                req.body.some((g) => typeof g !== 'string')
            ) {
                helpers.formatApiResponse(400, res);
                return;
            }

            await meta.settings.setOne(
                'passkeys',
                'pwdlessEnforcedGroups',
                JSON.stringify(req.body)
            );

            helpers.formatApiResponse(200, res);
        }
    );

    routeHelpers.setupApiRoute(
        router,
        'post',
        '/passkeys/login',
        [],
        async (req, res) => {
            const loginRequest = await plugin._f2l.assertionOptions();
            loginRequest.challenge = b64uEncode(loginRequest.challenge);
            req.session.passkeysLoginRequest = loginRequest;

            helpers.formatApiResponse(200, res, loginRequest);
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

plugin.getLoginStrategy = function (strategies, callback) {
    passport.use(
        'passkey',
        new PasskeyStrategy(
            async (req, assertion) => {
                const encodedUserHandle = assertion.response?.userHandle;
                if (typeof encodedUserHandle !== 'string') {
                    return null;
                }
                const uid = parseInt(b64uDecode(encodedUserHandle), 10);
                if (Number.isNaN(uid)) {
                    return null;
                }

                const publicKey = await plugin.getAuthnPublicKey(
                    uid,
                    assertion.id
                );
                if (publicKey === null) {
                    return null;
                }

                const prevCounter = await plugin.getAuthnCount(assertion.id);
                if (prevCounter === null) {
                    return null;
                }

                const assertionExpectations = {
                    challenge: req.session.passkeysLoginRequest.challenge,
                    origin,
                    factor: 'first',
                    publicKey,
                    prevCounter,
                    userHandle: encodedUserHandle,
                };

                assertion.rawId = Uint8Array.from(
                    b64uDecode(assertion.rawId),
                    (c) => c.charCodeAt(0)
                ).buffer;
                const result = await plugin._f2l.assertionResult(
                    assertion,
                    assertionExpectations
                );
                const count = result.authnrData.get('counter');
                await plugin.updateAuthnCount(assertion.id, count);

                delete req.session.passkeysLoginRequest;

                return { uid };
            }
        )
    );

    strategies.push({
        name: 'passkey',
        url: '/login/passkey',
        urlMethod: 'get',
        callbackURL: '/auth/passkey',
        callbackMethod: 'get',
        checkState: false,
        successUrl: '/',
        failureUrl: '/login?error=Unauthorized',
        icon: 'fa-key',
        labels: {
            login: '[[passkeys:login-with-passkey]]',
            register: '[[passkeys:login-with-passkey]]', // will show up on register page, nothing we can do
        },
    });

    callback(null, strategies);
};

plugin.checkPwdlessLogin = async (data) => {
    const uid = await user.getUidByUsername(data.userData.username);

    if (
        uid > 0 &&
        (await plugin.hasPasskey(uid)) &&
        (await plugin.forcePwdless(uid))
    ) {
        throw new Error('[[passkeys:pwdless.login-disallowed]]');
    } else {
        return data;
    }
};

plugin.checkForcePasskey = async ({ req, res }) => {
    if (!req.user) {
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

    if (await plugin.hasPasskey(req.user.uid)) {
        return;
    }

    if (!(await plugin.forcePwdless(req.user.uid))) {
        return;
    }

    const redirect = requestPath.replace(nconf.get('relative_path'), '');

    if (req.url.startsWith('/admin') || !req.url.match('passkeys')) {
        if (res.locals.isAPI) {
            controllerHelpers.formatApiResponse(
                401,
                res,
                new Error('[[passkeys:passkey-required]]')
            );
            return;
        } else {
            controllerHelpers.redirect(res, `/me/passkeys?next=${redirect}`);
        }
    }
};

// --------- //
// Utilities //
// --------- //

plugin.getAuthnPublicKey = async (uid, id) =>
    db.getObjectField(`passkeys:pubkeys:${uid}`, id);

plugin.getAuthnCount = async (id) => db.sortedSetScore(`passkeys:counters`, id);

plugin.updateAuthnCount = async (id, count) =>
    db.sortedSetAdd(`passkeys:counters`, count, id);

plugin.saveAuthn = (uid, authnrData) => {
    const counter = authnrData.get('counter');
    const publicKey = authnrData.get('credentialPublicKeyPem');
    const id = b64uEncode(authnrData.get('credId'));
    db.setObjectField(`passkeys:pubkeys:${uid}`, id, publicKey);
    db.sortedSetAdd(`passkeys:counters`, counter, id);
};

plugin.hasPasskey = async (uid) => db.exists(`passkeys:pubkeys:${uid}`);

plugin.clearAllKeys = async (uid) => {
    const keyIds = await db.getObjectKeys(`passkeys:pubkeys:${uid}`);
    await db.sortedSetRemove('passkeys:counters', keyIds);
    await db.delete(`passkeys:pubkeys:${uid}`);
};

plugin.getPwdlessEnforcedGroups = async () => {
    return JSON.parse(
        (await meta.settings.getOne('passkeys', 'pwdlessEnforcedGroups')) ??
            '[]'
    );
};

plugin.forcePwdless = async (uid) =>
    await groups.isMemberOfAny(uid, await plugin.getPwdlessEnforcedGroups());

plugin.getUsers = async function () {
    return db
        .getObjectKeys('passkeys:pubkeys') // FIXME: does not work
        .then((uids) =>
            user.getUsersFields(uids, ['username', 'userslug', 'picture'])
        );
};

module.exports = plugin;
