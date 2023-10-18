'use strict';

define('forum/login', ['api', 'alerts'], (api, alerts) => ({
    init() {
        const btn = this.getButton();
        btn?.addEventListener('click', (event) => {
            event.preventDefault();
            if (btn.disabled) return;
            btn.disabled = true;

            this.triggerLogin();
        });
    },

    getButton() {
        return document.querySelector('.alt-logins .passkey a.btn');
    },

    async triggerLogin() {
        api.post('/plugins/passkeys/login', {})
            .then(async (request) => {
                const webauthnJSON = await import('@github/webauthn-json');
                const response = await webauthnJSON.get({
                    publicKey: request,
                    mediation: 'optional',
                });

                alerts.info('[[passkeys:logging-in]]');

                // hack to redirect as GET
                const form = document.createElement('form');
                form.method = 'get';
                form.action = '/auth/passkey';

                const input = document.createElement('input');
                input.type = 'hidden';
                input.name = 'assertion';
                input.value = JSON.stringify(response);
                form.appendChild(input);

                document.body.appendChild(form);
                form.submit();
            })
            .catch((e) => {
                alerts.error(e);
                this.getButton().disabled = false;
            });
    },
}));
