'use strict';

define('forum/register', [], () => ({
    init() {
        const altCol = document.querySelector(
            '.register > div > div > div:nth-child(2)'
        );
        const options = altCol?.querySelectorAll('.alt-logins > li') ?? [];

        // passkeys is an alternative login, but not an alternative registration
        // this removes the button, or the entire column if there are no more options
        // (the screen might flash, but there is not much we can do about that)

        if (options.length <= 1) {
            altCol?.remove();
        } else {
            altCol?.querySelector('.passkey')?.remove();
        }
    },
}));
