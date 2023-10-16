'use strict';

define('forum/admin/passkeys', ['api', 'alerts'], (api, alerts) => ({
    init() {
        const btn = this.getButton();
        btn.addEventListener('click', () => {
            if (btn.disabled) return;
            btn.disabled = true;

            this.savePwdlessEnforcedGroups();
        });
    },

    getButton() {
        return document.getElementById('save');
    },

    getSelectedGroups() {
        return Array.from(
            document.getElementById('pwdlessEnforcedGroups').selectedOptions,
            (option) => option.value
        );
    },

    async savePwdlessEnforcedGroups() {
        await api
            .post(
                '/plugins/passkeys/pwdless-enforced-groups',
                this.getSelectedGroups()
            )
            .then(() =>
                alerts.success(
                    '[[passkeys:admin.pwdless-enforced-groups.saved]]'
                )
            )
            .catch(alerts.error)
            .finally(() => (this.getButton().disabled = false));
    },
}));
