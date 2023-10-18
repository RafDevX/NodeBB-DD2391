#import "@preview/tablex:0.0.5": tablex, colspanx, rowspanx

#set page("a4")
#set text(12pt)
#show heading: set block(above: 1.4em, below: 1em)
#align(center + horizon)[
  #heading(outlined: false)[Cybersecurity Project DD2391/DD2394]
  #heading(outlined: false, level: 2)[Group 2]

  #v(20pt)

  #grid(columns: (120pt, 120pt), row-gutter: 20pt, align(center)[
    Diogo Correia\
    #link("mailto:diogotc@kth.se")
  ], align(center)[
    Neil Prabhu\
    #link("mailto:nprabhu@kth.se")
  ], align(center)[
    Rafael Oliveira\
    #link("mailto:rmfseo@kth.se")
  ], align(center)[
    Yannik Tausch\
    #link("mailto:yannikt@kth.se")
  ])

  #v(20pt)

  #smallcaps[october 2023]

  Cybersecurity Overview, KTH Royal Institute of Technology
]

#pagebreak()
#set par(justify: true)
#set heading(numbering: "1.1.")
#set page(paper: "a4", header: [
  #set text(10pt)
  #smallcaps[Cybersecurity Project DD2391/DD2394]
  #h(1fr) #smallcaps[Group 2]
  #line(length: 100%, stroke: 0.5pt + rgb("#888"))
], footer: [
  #set align(right)
  #set text(10pt)
  #line(length: 100%, stroke: 0.5pt + rgb("#888"))
  Page
  #counter(page).display("1 of 1", both: true)
])
#counter(page).update(1)

#outline()

#pagebreak()

= Problems

== Database Leakage and Corruption <db-leakage>

In today's digital age, it is important to ensure data is secure. It is
unfortunately common for databases to be exposed to the internet
#cite("shodan-mysql", "shodan-mongodb"), which leaves them vulnerable to remote
attacks. If a malicious actor manages to gain access to the database, for
example, by brute-forcing the password, it can access, expose and tamper with
its content. The default installation of MongoDB listens on all interfaces,
which means that if a firewall is not configured, it would be exposed to the
internet, leaving it vulnerable.

NodeBB uses MongoDB (among other options) to persistently store its data, which
includes public information, such as posts and replies, but also personal or
sensitive information, like (hashed) passwords, names, email addresses, IP
addresses, API keys and so on. If this data were to be accessed or modified by
an unauthorized and/or malicious user, it could be used nefariously, and result
in spam, identity theft, social engineering attacks, and even being sold to the
highest bidder. Depending on the size and reputation of the NodeBB forum is
question, all of these could be a blow to its activity.

As such, we would like to prevent unauthorized and remote access to the
database, securing the data that it stores.

=== Chosen Countermeasures and Implementations

With this threat model in mind, we have devised two strategies to improve the
security of the database installation. As opposed to a bare metal installation,
we have opted to deploy containerized applications using *Docker* @docker.

Firstly, we used *Docker Compose* @docker-compose to deploy our NodeBB and
MongoDB instances. With this setup, both applications are run in an isolated
network that is not exposed to the internet @docker-networks. It is then
possible to expose specific ports of specific containers. We have exposed port
`4567` of the NodeBB container to allow access to the forum from the outside
world, while keeping port `27017` of the MongoDB container closed. In contrast
with spinning up two separate containers and then adding them to the same Docker
network, using Docker Compose abstracts this complexity away by automatically
creating a network for all the containers defined in `docker-compose.yml`.

Additionally, we generate a random 256-bit password for the `nodebb` database
user. The `mongo` Docker image supports providing custom scripts that are run
when the database is first created (i.e. the first time the container is
started) by placing them in the `/docker-entrypoint-initdb.d/` folder inside the
container. The script we created, `init_user.js`, adds a new user, `nodebb` to
the `nodebb` database, with full permissions over it. Its password is then
printed to the logs, allowing us to setup the database connection on NodeBB. We
have opted to use NodeJS' `crypto` library for the password generation instead
of `Math.random`, due to its secure randomness.

=== Difficulties and Solutions

During the implementation of these countermeasures, we have stumbled upon a few
challenges.

The Docker installation method is not listed on NodeBB's documentation
@nodebb-docs, which meant we had to figure out how to set it up ourselves. There
is, however, both a `Dockerfile` and a `docker-compose.yml` file in NodeBB's
repository @nodebb-repo, which we used as a guideline. NodeBB also provides an
official image, available as `ghcr.io/nodebb/nodebb`. Nevertheless, we had to
find a way to persist the `config.json` file, which stores the database
credentials and other configuration, inside the container. We had two requisites
for a solution to this problem: firstly, it would need to persist this file if
the container is destroyed (i.e. by running `docker compose down`); secondly, we
should still be able to run the web installer from a clean install.

The first approach we took to fix this problem only satisfied the first
requisite, since we stopped being able to do a clean install from an empty
database. We had mounted the `config.json` file using Docker bind mounts
@docker-bind-mounts, but that meant that the file would have to be created
beforehand, (which would not work on a clean database) otherwise Docker would
mount it as a directory instead.

On our second and final approach, we found out, by inspecting the code, that
NodeBB supports passing the path to the `config.json` file in the `config`
(lowercase) environment variable. We have then set this variable to
`/etc/nodebb/config.json` and persisted the `/etc/nodebb` directory using a
Docker volume @docker-volumes.

Additionally, for the purpose of this project, we have not persisted files
uploaded to the NodeBB forum (e.g. attachments to posts, profile pictures, and
more), as they are not needed for the demonstration of the countermeasures.

Finally, as can be evidenced by the difficulties mentioned above, the lack of
documentation for NodeBB held us back in certain situations, and we had to
resort to reading the source code instead.

=== Final Thoughts

To conclude, by avoiding the exposure of the database to the internet we should
prevent attacks from remote users. Nevertheless, this does not mean we do not
need to supplement this measures with additional precautions, such as monitoring
logs and network traffic, rotating passwords regularly, and other security
measures, depending on the sensitivity of the information in the forum.

#pagebreak()
== Unauthorized Access <unauthorizedAccess>

=== Possible Attack Scenarios
An attacker could target a *specific user* and try to brute-force their password in an online attack. The attacker could use a list of *common passwords* such as from the SecLists project #footnote[https://github.com/danielmiessler/SecLists/tree/master/Passwords/Common-Credentials] or may have obtained a *specific list of passwords* that the target user uses on different websites, which could be likely candidates for the user's credentials for the NodeBB instance, or other likely passwords for that specific user.

Additionally, the attacker could facilitate a botnet to *distribute* their attack over many IP addresses instead of originating all requests from a single IP.

The attacker's goal could be either to compromise *confidentiality* and *integrity* by guessing the user's password and taking over their account, or to compromise *availability* by triggering an account lockout mechanism designed to prevent password guessing.
Although compromising availability is strictly speaking not part of somebody gaining "unauthorized access", these two aspects have to be considered together when designing countermeasures, as their effectiveness depends on each other.

Alternatively to targeting a specific user, the attacker could also run an *untargeted attack* by brute-forcing passwords of multiple users.

All of these different attack variants can be arbitrarily combined.

=== Taxonomy
In order to maintain an overview over the different attack scenarios, we introduce a 4-letter notation to distinguish between the different kinds of attacks, which is outlined in @notation.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    inset: 10pt,
    align: (left, left, left, left),
    [*Target*], [*Password List*], [*Distributed?*], [*Attacker Goal*],
    [*`T`*: targeted \ *`U`*: untargeted],
    [*`C`*: common list \ *`S`*: specific for (each) user],
    [*`D`*: distributed \ *`N`*: not distributed],
    [*`O`*: account takeover \ *`L`*: account lockout]
  ),
  caption: [Notation for _Unauthorized Access_ Attack Scenarios]
) <notation>

For example, TSDO denotes the attack scenario in which one specific user account is targeted, using a specific password list tailored for this user, and a distributed botnet, to achieve an account takeover.

To describe a set of multiple attack scenarios, any letter can be replaced with `X` to denote "any". For example, UXXL denotes all attack scenarios aiming to lock out as many users as possible from their accounts.

We should point out that there is no difference between XCXL and XSXL attacks because any set of passwords can be used to trigger an account lockout if such a system is implemented. Any other combination of attack properties is imaginable and should be subject to consideration.

=== NodeBB Default Countermeasures
Before discussing possible additional countermeasures, we first examined the countermeasures that NodeBB is configured with by default.

These countermeasures include a setting of allowing a maximum of 5 login attempts per hour, per user.
If this limit is exceeded, the user account is locked for 60 minutes. Successful logins reset the number of login attempts, and so does the 60-minute lockout.
Unfortunately, we could not find an explanation of this setting in the NodeBB documentation but it appears in the NodeBB admin panel under `Settings`~#sym.arrow~`Users`~#sym.arrow~`Account`~`Protection`, as can be seen in @accountSettings.

#figure(
  image("account_settings.svg", height: 20%),
  caption: "NodeBB Settings Related to Account Protection"
) <accountSettings>

The behaviour of this account locking mechanism can be verified in the NodeBB source code #footnote[https://github.com/NodeBB/NodeBB/blob/0acb2fcfe472cb745618e806e41af3e551580fad/src/user/auth.js#L16C5-L40]. A locked account can be recovered by the user themselves by receiving a password reset link via email.

For validation and demonstration purposes, we developed a Python script #footnote[available at `unauthorized_access/bruteforce.py` in the GitHub submission] that executes a TCNX attack against a specific target user. We could validate that user accounts are indeed locked according to the setting. The script can easily be modified for untargeted attacks, and a modification for individual password lists per user is also possible.

We could not identify any additional countermeasures by NodeBB against the threat models outlined in this section of the report, for example automatic IP blocking (manual IP blocking is possible though). Therefore, the default protections do not differentiate between distributed and non-distributed attacks.

Since the default account locking settings lead to a maximum of 120 login attempts per day (43.800 per year), they are mostly sufficient when used in combination with a strong password policy (which is configurable with NodeBB)#footnote[For example, there exist $62^16 approx 4 dot 10^28$ different alphanumeric passwords of length 16.]. Therefore, NodeBB by default effectively protects against TCXO attacks. For TSXO attacks, it should be noted that a targeted attack with a manageable list of possible password candidates could be run in the background over a long period of time without the user noticing.

NodeBB's protection against UXXO attacks are not sufficient because a single attacker can guess 43.800 passwords per year, _per user_. Assuming a large online forum with 100.000 users, this leads to a total amount of 4.4 billion guesses per year, which is not an acceptable risk, even if a strong password policy is employed. It is possible even among long passwords to choose a weak password that is not detectable automatically. Some users will choose these passwords, allowing their account to be taken over with this attack.

Finally, NodeBB's countermeasures against XXXL account lockout attacks are effective in the sense that a user can always reset a lockout period by receiving a password reset link via email.
However, this comes with two limitations: First, being required to reset your password via email is in some sense a degradation in availability; and second, there is nothing preventing a malicious attacker from spamming a large number of login requests, locking the account again faster than time it takes the user to log in after unlocking it.
However, the default solution is better than nothing, and the request spamming could easily be mitigated by, for example, a web proxy in front of the application.

The default situation is summarized in @defaultMitigations.

#let tableColors = (
  none, none, none, none, none, none,
  none, green, red, red, green, none,
  none, red, red, red, red, none,
  none, yellow, yellow, yellow, yellow, none,
  none, none, none, none, none, none,
  none, none, none, none, none, none,
)
#figure(
  grid(
    columns: (auto),
    rows: (auto, auto),
    gutter: 10pt,
    tablex(
      columns: (20pt, 50pt, 50pt, 50pt, 50pt, 20pt),
      rows: (20pt, 50pt, 50pt, 50pt, 50pt, 20pt),
      align: horizon + center,
      fill: (col, row) => tableColors.at(col + 6*row),
      [], [*T*], colspanx(2)[*untargeted*], [*T*], [],
      [*C*], [TCDO], [UCDO], [UCNO], [TCNO], rowspanx(2, rotate(-90deg, text(hyphenate: false)[*takeover*])),
      rowspanx(2, rotate(-90deg, text(hyphenate: false)[*specific*])), [TSDO], [USDO], [USNO], [TSNO],
      rowspanx(2)[TXDL], rowspanx(2)[UXDL], rowspanx(2)[UXNL], rowspanx(2)[TXNL], rowspanx(2, rotate(-90deg, text(hyphenate: false)[*lockout*])),
      [*C*],
      [], colspanx(2)[*distributed*], colspanx(2)[*not distributed*],
    ),
    [Legend: #text(green)[■] good protection, #text(yellow)[■] some protection, #text(red)[■] no protection],
    v(5pt)
  ),
  caption: [NodeBB Default _Unauthorized Access_ Mitigations]
) <defaultMitigations>

=== Countermeasure: Login CAPTCHA
To improve the security of the application with regard to the threat models outlined in this chapter, different additional countermeasures were considered.
We chose to actually implement a CAPTCHA challenge that has to solved for each login attempt to make automated login attempts less feasible.

Such a CAPTCHA can be accomplished by installing the NodeBB plugin `nodebb-plugin-spam-be-gone` #footnote[https://github.com/akhoury/nodebb-plugin-spam-be-gone]. In addition to executing CAPTCHAs when a new post is created, it also supports Google reCAPTCHA #footnote[https://www.google.com/recaptcha] on the NodeBB login page.

The installation is described in the appropriate README file of our GitHub repository. When setting up the plugin, we experienced issues such as error messages on the login page UI, either indicating a misconfiguration or a failed CAPTCHA, although the CAPTCHA was solved correctly. These issues could be resolved by making sure that a reCAPTCHA "v2" with checkbox "I am not a robot" API key is being used. Other options are not supported by the NodeBB plugin.

With the CAPTCHA enabled while assuming that it indeed prevents almost all automated login attempts, the security considerations of our NodeBB instance change. It is no longer feasible to perform untargeted (UXXX) attacks because they require too many login attempts, which would have to be executed manually.

Additionally, distributed (XXDX) attacks, as long as we limit our scope to botnets, are no longer feasible for the same reason.

Nevertheless, TSNO attacks are still realistic, and it is still possible to force a targeted user into resetting their password with a non-distributed attack - meaning that TXNL attacks are not fully defended against.

A full final overview is given in @finalMitigations.

#let tableColors = (
  none, none, none, none, none, none,
  none, green, green, green, green, none,
  none, green, green, green, red, none,
  none, green, green, green, yellow, none,
  none, none, none, none, none, none,
  none, none, none, none, none, none,
)
#figure(
  grid(
    columns: (auto),
    rows: (auto, auto),
    gutter: 10pt,
    tablex(
      columns: (20pt, 50pt, 50pt, 50pt, 50pt, 20pt),
      rows: (20pt, 50pt, 50pt, 50pt, 50pt, 20pt),
      align: horizon + center,
      fill: (col, row) => tableColors.at(col + 6*row),
      [], [*T*], colspanx(2)[*untargeted*], [*T*], [],
      [*C*], [TCDO], [UCDO], [UCNO], [TCNO], rowspanx(2, rotate(-90deg, text(hyphenate: false)[*takeover*])),
      rowspanx(2, rotate(-90deg, text(hyphenate: false)[*specific*])), [TSDO], [USDO], [USNO], [TSNO],
      rowspanx(2)[TXDL], rowspanx(2)[UXDL], rowspanx(2)[UXNL], rowspanx(2)[TXNL], rowspanx(2, rotate(-90deg, text(hyphenate: false)[*lockout*])),
      [*C*],
      [], colspanx(2)[*distributed*], colspanx(2)[*not distributed*],
    ),
    [Legend: #text(green)[■] good protection, #text(yellow)[■] some protection, #text(red)[■] no protection],
    v(5pt)
  ),
  caption: [NodeBB _Unauthorized Access_ Mitigations with CAPTCHA enabled]
) <finalMitigations>

=== Additional Considerations
As outlined above, a secure password policy should be in place for the mitigations to be effective.

Different approaches such as IP rate limiting and IP address blocking would be appropriate to further improve the security of the application.

We also did not evaluate the security of password reset links sent out via email by NodeBB.

Using Google reCAPTCHA has privacy implications, since every time a user visits the login site, a request is sent to Google. Evaluating these implications was out of scope for this report.

Besides that, CAPTCHAs usually negatively impact the UX of an application.
However, when implemented correctly, they usually present a good tradeoff between usability and security, as the security benefits can be immense (as outlined in this chapter).
Modern CAPTCHA technologies such as Google reCAPTCHA v3 #footnote[https://developers.google.com/recaptcha/docs/v3] (which is unfortunately not supported by `nodebb-plugin-spam-be-gone`) allow verifying the legitimacy of a request without user intervention by collecting data in the background, removing the UX impact.
Evaluating these kinds of CAPTCHAs for our application was out of scope for this report.

#pagebreak()
== Unauthorized Administration <unauthorized-admin>

In the default configuration of NodeBB, user accounts are only protected by a
username and a password. Even though passwords can be relatively secure if they
are long, unique, and randomly generated, *they might still be compromised*, for
example, by phishing attacks. This is especially problematic for site
administrators, whose accounts can access and modify site settings, forum posts,
user information, and other sensitive data.

As such, we would like to *lessen the impact in case of compromised
administrator credentials*. One way to achieve that goal is through the use of
*Two-Factor Authentication*, which is readily available as an official NodeBB
plugin, `nodebb-plugin-2factor` @nodebb-plugin-2factor, and is installed by
default, though it has to be enabled manually from the administrator panel.

Instead of pursuing this approach, however, we *decided to support Passkeys*, a
new secure passwordless authentication method developed by the FIDO Alliance,
based on public-key cryptography @fido-passkeys. Passkeys rely on an _authenticator_,
which might be a secure chip on the user's device (e.g., a mobile phone) or a
separate hardware authentication device (such as a security key, like a
YubiKey). This authenticator holds private keys for each associated passkey and
performs the necessary cryptographic operations to securely identify the user to
a _relying party_, such as the NodeBB website: the relying party generates a
challenge which the authenticator cryptographically signs, enabling the relying
party to verify that the provided challenge response has been signed by the
private key associated with the public key that was mapped to the user during
registration.

Using passkeys also counts as two-factor authentication, completely replacing
combinations such as a password + one-time passwords (OTP), since they are
validated on-device with biometrics or a PIN code, therefore requiring both a "something
you have" factor and a "something you are"/"something you know" factor. They are
also phishing resistant, which neither passwords nor OTP are, due to their
cryptographic nature: the private key is never sent to the server, and the
browser validates that the origin matches the expected value before forwarding
the authentication response. Furthermore, they are also more convenient because
users do not have to remember passwords, and each passkey is only used in a
single site. Additionally, passkeys obsolete the need for users to enter their
username, since the authentication challenge response also includes a unique
identifier of the user associated with the passkey, and websites store mappings
between users and their registered passkey public keys.

All of these properties make passkeys a very compelling option for secure
authentication. As such, we came to the conclusion that adding passkey support
to NodeBB would be the most effective way of mitigating situations where
administrator users' passwords are compromised.

The downside for passkeys is that support is still being rolled out, which means
not every device and operating system supports creating, storing, and using
passkeys @passkeys-devices. This is also true for the NodeBB landscape in
particular, where there is still no NodeBB plugin for passkeys @nodebb-passkeys,
due to the technology being so new, so we had to develop our own. Fortunately,
the hardware security keys support in the two-factor plugin for NodeBB
@nodebb-plugin-2factor is very similar to what we want to implement, so we used
it as inspiration for this proof-of-concept.

We extended our `Dockerfile` to copy the plugin's files into the container and
automatically install it to NodeBB, so an administrator only needs to activate
the plugin in the Admin Control Panel ("Admin" > "Extend" > "Plugins" > "`nodebb-plugin-passkeys`" > "Activate"
> "Confirm" > "Rebuild & Restart" > "Confirm").

This simple procedure will instantly enable all users site-wide to register a
passkey to their account, by accessing "Settings" > "Passkeys", allowing them to
opt-in to a more secure experience. After registering a passkey, users can use
it to sign into the website using the "Login with a Passkey" button shown on the
regular login page, under "Alternative Logins". In order to support the login
flow, we implemented a custom login strategy in accordance with `passport`'s
specification @passport. Our plugin supplies this strategy to NodeBB, which
invokes it when it is necessary to direct, validate, or support a user sign-in
process.

There is a plethora of different parameters to tune in relation to WebAuthn
@w3c-webauthn (the W3C standard supporting passkeys) operations, so we had to
make certain design decisions in accordance with what we believed to be best in
terms of security, feasibility, and user experience. Of these design choices, we
point out:

- We require both user presence and user verification for an authentication
  attempt to be successful, ensuring that the authenticator makes use of a second
  authentication factor (i.e., prompts for a PIN code, biometric credentials, or
  another equivalent method);
- In order to simplify the passkey registration process, and to limit the amount
  of personal identifying information provided to us, we do not require any form
  of authenticator attestation by a Certificate Authority;
- We carefully selected which algorithms @cose-algos to accept, and in which order
  of preference, having settled on ECDSA, then RSASSA-PSS, and then
  RSASSA-PKCS1-v1_5, and for each of those suites preferring algorithms using
  SHA-512, then SHA-384, and then SHA-256. Originally we planned on listing COSE
  algorithm `-8`, EdDSA, as our preferential algorithm, but one of our
  dependencies @fido2-lib does not yet support it.

Moreover, we implemented a *Per-Group Passwordless Enforcement* feature that
allows administrators (through "Admin" > "Plugins" > "Passkeys") to configure
passwordless requirements for specific groups of users (such as the
`administrators` group, or even all `registered-users`). Any groups selected
using this feature will require its members to register a passkey if they have
not already (users cannot view any pages or perform any action until they do),
and members of such a group can no longer use their password to login after they
have registered a passkey, therefore being forced to always login using a
passkey, which significantly improves security as outlined above. We believe
this feature is essential to help further the site's security, and our
implementation supporting enforcement based on arbitrary groups gives
administrators enormous flexibility. Evidently, to solve this specific #smallcaps[Unauthorized Administration] problem
for this project, we recommend enabling passwordless enforcement for the
`administrators` group.

In conclusion, we consider that passkeys are a groundbreaking authentication
method due to their simplicity, ease of use, and security-centered design, so we
decided that their adoption (and, ideally, the enforcement of a policy mandating
their adoption) would bring immense benefits to NodeBB's security stage,
near-completely eliminating the potential consequences of an administrator
account's password being compromised. To this effect, we implemented a new
plugin to add passkey support to NodeBB and allow sites to make use of this
technology.

#pagebreak()
= Group Members

== Diogo Correia <diogo>

Diogo already had prior experience with Docker and JavaScript, which was a
valuable skill in this project. Along with #link(<rafael>)[Rafael], he worked on
the #link(<unauthorized-admin>)[Unauthorized Administration]
task, deliberating on what was the best course of action for solving the problem
at hands. It was first decided that we would implement two-factor
authentication, but upon finding out that the plugin already existed, and that a
solution only included clicking on a few buttons in the web interface, Diogo
decided to suggest *passkeys* as an alternative solution.

Therefore, Diogo and Rafael started working on a custom NodeBB plugin for
passkeys support, which was based on the already existing two-factor plugin.
Diogo mainly adapted the registration of a security key 2FA token to a passkey
registration flow, as well as some code cleanup. He also contributed to the
passkey login flow, but the bulk of the work for that was done by Rafael.

Getting this plugin together involved reading NodeBB's source code, as well as
reading FIDO specifications, since there is not a lot of documentation available
for the topic.

Both Diogo and Rafael worked on the report for this problem, with Diogo doing
the introduction to the topic, comparison with two-factor authentication, and
the advantages and disadvantages of passkeys.

Additionally, Diogo also worked on the #link(<db-leakage>)[Database Leakage] task,
by fixing the problem where clean installs stopped being possible after
persisting the config file. He also contributed to the respective section on the
report.

Finally, Diogo setup the document for the report, using Typst, along with the
cover page.

#pagebreak()
== Neil Prabhu <neil>

Before this project, Neil had a basic understanding of web applications and
database management, but had never worked with NodeBB. Similarly, Docker and
containerization were tools/technologies that Neil had extremely limited
experience in. Therefore, the learning curve was steep and required him to dive
headfirst into technologies that were entirely new to him, but Neil was eager to
embrace them.

One of the most valuable aspects of this journey for Neil was the opportunity to
shadow other group members who had more experience with NodeBB and Docker.
Through collaboration and learning from his group members' expertise, Neil
gained practical insights into these technologies. The other group mates shared
their knowledge about configuring and deploying NodeBB within Docker Compose
stacks, managing Docker networks, and maintaining containerized applications.
Neil recalls that he was fortunate to have experienced team members to turn to
for guidance during the implementation phase. Specifically, Neil remembers
struggling with Docker network configurations and compatibility issues with the
database management system, and he recollects that it was through the groups'
mentorship that he gained a better understanding of how to overcome these
hurdles.

Specifically, Neil was responsible for persisting the NodeBB configuration since
there was no official documentation about how to do that when deploying NodeBB
with Docker. Neil created a Docker volume to store the NodeBB data, especially
the database configuration. The configuration of the Docker volume is now part
of our Docker Compose stack. Consequently, whenever the Docker Compose stack is
restarted, NodeBB loads the persisted data from the volume, ensuring that no
repeated configuration is necessary. This also works for updates of the NodeBB
container. Lastly, Neil was responsible for completing the _Database Leakage and Corruption_ chapter
of this report.

#pagebreak()
== Rafael Oliveira <rafael>

Having already prior experience with most of the technologies involved in this
project, Rafael's skillset and reasoning were crucial for its development. He
mainly worked with #link(<diogo>)[Diogo] on the #link(<unauthorized-admin>)[_Unauthorized Administration_] task,
participating in the original discussion that first established our group's
point of view regarding passkeys being more relevant for this context than
traditional Two-Factor Authentication.

He set up the first skeletal structure of our new NodeBB passkeys plugin, and
actively reviewed Diogo's contribution of Passkey Registration to that plugin,
having refactored small parts.

For the most part, however, Rafael developed the login functionality of the
passkeys plugin, widely researching the best practices on how one would
implement such a feature; and due to NodeBB's poor documentation regarding
plugins, this mostly meant reading through several repositories' source code,
including NodeBB itself, multiple existing plugins with one or two similar
aspects, and some existing `passport` strategies. Browsing through tens of
resources at a time, including specification reference guides and implementation
libraries' documentation, he wrote and tested the majority of the complex login
challenge-response logic (and all the visual page, API endpoints, and routing
required to support that), counting also on Diogo's assistance at the end to
refactor some parts and fix a few bugs.

Additionally, Rafael implemented the per-group passwordless enforcement feature,
which is arguably the cornerstone of our solution to the #link(<unauthorized-admin>)[_Unauthorized Administration_] problem
for this project. He also wrote the `README.md` file at the root of the project
repository, explaining how to configure and run a NodeBB instance that showcases
all the solutions we developed for the three problems we worked on during the
course of this project.

Diogo and Rafael both worked on @unauthorized-admin of this report, pertaining
to the _Unauthorized Administration_ problem, with Rafael having written the
entirety of the second half, which outlines the technical details of our
solution and details a conclusion of our work on that front.

Rafael also introduced the initial `docker-compose.yml` configuration for
running NodeBB, which has since been greatly iterated on by #link(<diogo>)[Diogo] and #link(<neil>)[Neil].

Finally, Rafael reviewed every single part of the project, including all lines
of code and all parts of this report not authored by him. He provided
constructive feedback and requested as many changes as necessary from the
remaining group members until he was satisfied with the end product.

#pagebreak()
== Yannik Tausch
While the different attack scenarios and possible mitigations of the _Unauthorized Access_ chapter were discussed in our group, including the choice of selecting a login CAPTCHA as a countermeasure, Yannik contributed the categorization of possible attack scenarios and their taxonomy to the _Unauthorized Access_ chapter of this report.
Related to this chapter, he also researched the default countermeasures of NodeBB and evaluated their impact on the security of the application within the attack scenario taxonomy.

Yannik also developed the password brute-force Python script that can be used to demonstrate the strengths and weaknesses of the default NodeBB countermeasures against _Unauthorized Access_ attack scenarios.
Additionally, he was responsible for implementing the login CAPTCHA countermeasure, including the solving of problems that occurred during the setup.
Also, Yannik put the entire _Unauthorized Access_ chapter of this report into actual words.

Additionally, Yannik helped other group members with the Docker setup of the application and contributed his knowledge about the initialization of the MongoDB Docker container.

Finally, Yannik reviewed every chapter of this report he did not write himself.

#pagebreak()
#show bibliography: set heading(numbering: "1.")
#bibliography("references.yml", title: "References")
