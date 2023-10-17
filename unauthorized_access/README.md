# Unauthorized Access
## Bruteforce Script
The bruteforce script `bruteforce.py` was developed for Python 3.11 or later but it probably also works with earlier 3.x versions of Python.

To use it, follow these steps:
1. `pip -r requirements.txt`
2. Set the target user in the script (`alice` by default)
3. Execute the script

## Countermeasures Setup
To set up the countermeasure explained in the report, follow these steps:

1. Login as an administrator in NodeBB
2. Navigate to `Admin` &rarr; `Extend` &rarr; `Plugins` &rarr; `Find Plugins`
3. Install the `nodebb-plugin-spam-be-gone` plugin
4. Activate the plugin
5. Click on `Restart & Rebuild`, as instructed by the UI.
6. Navigate to `Plugins` &rarr; `Spam Be Gone` &rarr; `Google reCAPTCHA`
7. Enable reCAPTCHA by ticking the box and enter reCAPCTHA private and public API keys. The API keys can be created in the [reCAPTCHA admin portal](https://www.google.com/recaptcha/admin) - it is important that you select a v2 key for "I am not a Robot" checkboxes, nothing else will work.
8. Tick the box to enable reCAPTCHA on the login page as well

## Sources
Source of wordlist.txt: https://github.com/danielmiessler/SecLists/blob/master/Passwords/Common-Credentials/10-million-password-list-top-100000.txt
