# NodeBB-DD2391

This repository contains Group 2's solution for the HT 2023 Cybersecurity Project for the DD2391/DD2394 courses at KTH Royal Institute of Technology.

In this project, we attempted to solve or mitigate three problems related to the [NodeBB](https://github.com/NodeBB/NodeBB) software:

1. **Database leakage and corruption:** the default configuration of the database and NodeBB may be insecure (see the installation notes). We would like to prevent any remote access to the database that is not mediated by NodeBB software.
2. **Unauthorized access:** user may try to bruteforce passwords, possibly using a botnet. We would like to limit failed login attempts without compromising availability.
3. **Unauthorized administration:** password of admin users may have been compromised.

## Step-by-step Instructions

In order to run our solution locally, please follow the steps below. Note that for `docker` commands, your user will need to be in the `docker` group, otherwise you will need to run them as root. Additionally, in some distributions Docker Compose is available as a subcommand of `docker` (i.e., you might need to use `docker compose` instead of `docker-compose`).

1. Clone the repository: `git clone git@github.com:RafDevX/NodeBB-DD2391.git`
2. Start the containers: `docker-compose up -d --build`
3. Show and watch logs: `docker-compose logs -f`
4. The first time NodeBB runs, it will spin up a web installer that can be accessed at `http://localhost:4567`. You should fill out the fields shown as specified below and then submit by pressing "Install NodeBB" at the bottom of the page:

    - Web Address: `http://localhost:4567` (or the domain where this will be hosted)
    - Administrator Username: any username of your choosing
    - Administrator E-mail: any e-mail of your choosing
    - Administrator Password: any password of your choosing
    - Database Type: MongoDB
    - MongoDB Host: `db`
    - MongoDB Port: `21017`
    - MongoDB Username: `nodebb`
    - MongoDB Password: this (randomly-generated) value is shown at the beginning of the DB logs (`docker-compose logs -f`) during first execution; copy-paste it here
    - MongoDB Database: `nodebb`

5. After installation is complete, you will be redirected by the web installer to the forum home page, where you may sign in using the administrator credentials you configured
6. Activate passkeys support by going to "Admin" > "Extend" > "Plugins" > "nodebb-plugin-passkeys" > "Activate" > "Confirm" > "Rebuild & Restart" > "Confirm"
7. Refresh the page after NodeBB says the rebuild has been completed
8. Enforce passwordless requirements for all Administrators in "Plugins" > "Passkeys" > (Select `administrators`) > "Save changes"
9. As you are an administrator, you will now be required to register a passkey (you could have also previously done so of your own volition in "Settings" > "Passkeys")
10. Activate login CAPTCHAs by navigating to "Admin" > "Extend" > "Plugins" > "nodebb-plugin-spam-be-gone" > "Activate" > "Confirm" > "Rebuild & Restart" > "Confirm"
11. Refresh the page after NodeBB says the rebuild has been completed
12. Go to "Plugins" > "Spam Be Gone" > "Google reCAPTCHA", check both checkboxes ("Enable Re-Captcha" and "Enable Re-Captcha on login page as well"), fill out with your API keys (that must be v2 keys for "I am not a Robot" checkboxes, created in [Google's reCAPTCHA Admin Portal](https://www.google.com/recaptcha/admin)), and press "Save changes"
13. After you have completed these steps, the system is fully configured and should be securely addressing/mitigating the problems described above. It is now production-ready!
14. Stop and remove the containers with `docker-compose down` (or `docker-compose down -v` to delete volumes as well, permanently destroying all stored data)
