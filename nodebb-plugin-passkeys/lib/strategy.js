'use strict';

const BaseStrategy = require('passport-strategy');

module.exports = class PasskeyStrategy extends BaseStrategy {
    constructor(verify) {
        super();
        this.verify = verify;
    }

    async authenticate(req) {
        if (req.method.toUpperCase() !== 'GET') {
            this.fail();
            return;
        }
        if (typeof req.query?.assertion !== 'string') {
            this.fail();
            return;
        }

        try {
            const assertion = JSON.parse(req.query.assertion);
            if (typeof assertion !== 'object') {
                this.fail();
                return;
            }

            const user = await this.verify(req, assertion);
            if (!user) {
                this.fail();
                return;
            }
            this.success(user);
        } catch (e) {
            this.fail();
        }
    }
};
