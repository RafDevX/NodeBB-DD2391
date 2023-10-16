'use strict';

const BaseStrategy = require('passport-strategy');

module.exports = class PasskeyStrategy extends BaseStrategy {
    opts = {
        loginPagePath: '/login',
        successPagePath: '/',
        failurePagePath: '/login',
    };

    constructor(opts, verify) {
        super();
        Object.assign(this.opts, opts);
        this.verify = verify;
    }

    async authenticate(req) {
        if (typeof req.uid === 'number' && req.uid > 0) {
            // HTTP 303 always changes method to GET when redirecting
            delete req.session.ongoingPasskeyLogin;
            this.redirect(this.opts.successPagePath, 303);
        } else if (req.method.toUpperCase() === 'POST') {
            if (!req.session.ongoingPasskeyLogin) {
                // HTTP 303 always changes method to GET when redirecting
                this.redirect(this.opts.failurePagePath, 303);
                return;
            } else if (typeof req.body?.assertion !== 'string') {
                delete req.session.ongoingPasskeyLogin;
                this.fail();
                return;
            }

            try {
                const assertion = JSON.parse(req.body.assertion);
                if (typeof assertion !== 'object') {
                    delete req.session.ongoingPasskeyLogin;
                    this.fail();
                }

                const user = await this.verify(req, assertion);
                if (user) {
                    delete req.session.ongoingPasskeyLogin;
                    this.success(user);
                } else {
                    delete req.session.ongoingPasskeyLogin;
                    this.fail();
                }
            } catch (e) {
                delete req.session.ongoingPasskeyLogin;
                this.fail();
            }
        } else {
            req.session.ongoingPasskeyLogin = true;
            this.redirect(this.opts.loginPagePath);
        }
    }
};
