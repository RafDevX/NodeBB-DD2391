'use strict';

const parent = module.parent.exports;

const passport = require.main.require('passport');
const nconf = require.main.require('nconf');
const winston = require.main.require('winston');
const validator = require.main.require('validator');
const async = require('async');
const fs = require('fs');
const path = require('path');
const base64url = require('base64url');

const groups = require.main.require('./src/groups');
const user = require.main.require('./src/user');
const meta = require.main.require('./src/meta');
const translator = require.main.require('./src/translator');
const helpers = require.main.require('./src/controllers/helpers');

const Controllers = {};


async function getGroups(set) {
	let groupNames = await groups.getGroups(set, 0, -1);
	groupNames = groupNames.filter(groupName => groupName && !groups.isPrivilegeGroup(groupName));

	return groupNames.map(groupName => ({
		name: validator.escape(String(groupName)),
		value: validator.escape(String(groupName)),
	}));
}

Controllers.renderChoices = async (req, res) => {
	const uid = res.locals['passkeys'] || req.uid;

  // TODO ?
	res.render('2fa-choices', {
		hasAuthn,
		hasTotp,
		hasBackupCodes,
		next: req.query.next,
		title: '[[2factor:title]]',
	});
};

Controllers.renderAuthnChallenge = async (req, res, next) => {
	const uid = res.locals['passkeys'] || req.uid;
	const single = parseInt(req.query.single, 10) === 1;

	if (req.session.tfa === true && ((req.query.next && !req.query.next.startsWith('/admin')) || !req.session.tfaForce)) {
		return res.redirect(nconf.get('relative_path') + (req.query.next || '/'));
	}

	if (!await parent.hasPasskeys(uid)) {
		return next();
	}

	const keyIds = await parent.getAuthnKeyIds(uid);
	let authnOptions;
	if (keyIds.length) {
		authnOptions = await parent._f2l.assertionOptions();
		authnOptions.allowCredentials = keyIds.map(keyId => ({
			id: keyId,
			type: 'public-key',
			transports: ['usb', 'ble', 'nfc'],
		}));
		authnOptions.challenge = base64url(authnOptions.challenge);
		req.session.authRequest = authnOptions.challenge;
	}

	res.render('login-authn', {
		single,
		authnOptions,
		next: req.query.next,
	});
};

Controllers.renderAdminPage = async function (req, res, next) {
	const groups = await getGroups('groups:createtime');

	async.parallel({
		image: async.apply(fs.readFile, path.join(__dirname, '../screenshots/profile.png'), {
			encoding: 'base64',
		}),
		users: async.apply(parent.getUsers),
	}, (err, data) => {
		if (err) {
			return next(err);
		}

		data.groups = groups;
		data.title = '[[passkeys:title]]';
		res.render('admin/plugins/passkeys', data);
	});
};

Controllers.renderSettings = async (req, res) => {
	const { username, userslug } = await user.getUserFields(res.locals.uid, ['username', 'userslug']);
	if (res.locals.uid !== req.user.uid) {
		return helpers.notAllowed(req, res);
	}

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

	let { tfaEnforcedGroups } = await meta.settings.get('passkeys');
	let forceTfa = false;

	tfaEnforcedGroups = JSON.parse(tfaEnforcedGroups || '[]');
	if (tfaEnforcedGroups.length && (await groups.isMemberOfGroups(req.user.uid, tfaEnforcedGroups)).includes(true)) {
		forceTfa = true;
	}

	const hasTotp = await parent.hasTotp(req.user.uid);
	const hasAuthn = await parent.hasAuthn(req.user.uid);
	res.render('account/passkeys', {
		title,
		breadcrumbs,
		forceTfa,
		hasTotp,
		hasAuthn,
		backupCodeCount: await parent.countBackupCodes(req.user.uid),
	});
};

module.exports = Controllers;
