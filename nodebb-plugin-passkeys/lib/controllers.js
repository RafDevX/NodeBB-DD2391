'use strict';

const parent = module.parent.exports;

const validator = require.main.require('validator');

const groups = require.main.require('./src/groups');
const user = require.main.require('./src/user');
const meta = require.main.require('./src/meta');
const translator = require.main.require('./src/translator');
const helpers = require.main.require('./src/controllers/helpers');

const controllers = {};

async function getGroups(set) {
    const nonPrivilegeGroups = await groups.getNonPrivilegeGroups(set, 0, -1);
    const pwdlessEnforcedGroups = await parent.getPwdlessEnforcedGroups();

    return nonPrivilegeGroups.map((group) => ({
        name: group.displayName,
        value: group.name,
        enabled: pwdlessEnforcedGroups.includes(group.name),
    }));
}

controllers.renderAdminPage = async function (req, res, next) {
    const [groups, users] = await Promise.all([
        getGroups('groups:createtime'),
        parent.getUsers(),
    ]);

    const data = { groups, users, title: '[[passkeys:title]]' };

    res.render('admin/plugins/passkeys', data);
};

controllers.renderSettingsPage = async (req, res) => {
    if (res.locals.uid !== req.user.uid) {
        // accessed URL does not match self user page
        return helpers.notAllowed(req, res);
    }

    const { username, userslug } = await user.getUserFields(res.locals.uid, [
        'username',
        'userslug',
    ]);

    const title = await translator.translate('[[passkeys:title]]');
    const breadcrumbs = helpers.buildBreadcrumbs([
        {
            text: username,
            url: `/user/${userslug}`,
        },
        {
            text: '[[passkeys:title]]',
        },
    ]);

    res.render('account/passkeys', {
        title,
        breadcrumbs,
        forcePwdless: await parent.forcePwdless(req.user.uid),
        hasPasskey: await parent.hasPasskey(req.user.uid),
    });
};

controllers.renderLoginPage = async (req, res) => {
    res.render('login/passkey');
};

module.exports = controllers;
