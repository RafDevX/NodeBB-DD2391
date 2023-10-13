'use strict';

define('forum/account/passkeys', ['api', 'alerts', 'bootbox'], function (api, alerts, bootbox) {
	var Settings = {};

	Settings.init = function () {
		document.querySelector('#content .list-group').addEventListener('click', (e) => {
			if (!e.target.closest('[data-action]') || Array.from(e.target.classList).includes('text-muted')) {
				return;
			}

			const action = e.target.getAttribute('data-action');
			Settings[action].call(e.target);
		});
	};

	Settings.disableAuthn = () => {
		bootbox.confirm('[[passkeys:user.manage.disableAuthn]]', function (confirm) {
			if (confirm) {
				api.del('/plugins/passkeys').then(ajaxify.refresh).catch(alerts.error);
			}
		});
	};

	Settings.setupAuthn = function () {
		const self = this;
		self.classList.add('text-muted');
		const modal = bootbox.dialog({
			message: '[[passkeys:authn.modal.content]]',
			closeButton: false,
			className: 'text-center',
		});
		api.get('/plugins/passkeys/register', {}).then(async (request) => {
			try {
				const webauthnJSON = await import('@github/webauthn-json');
				const response = await webauthnJSON.create({
					publicKey: request,
				});
				modal.modal('hide');

				api.post('/plugins/passkeys/register', response).then(() => {
					alerts.success('[[passkeys:authn.success]]');
					setTimeout(document.location.reload.bind(document.location), 1000);
				}).catch(alerts.error);
			} catch (e) {
				modal.modal('hide');
				self.classList.remove('disabled');
				alerts.alert({
					message: '[[passkeys:authn.error]]',
					timeout: 2500,
				});
			}
		});
	};

	return Settings;
});
