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
== Unauthorized Access

// TODO 2 pages

#pagebreak()
== Unauthorized Administration <unauthorized-admin>

In the default configuration of NodeBB, user accounts are only protected by a
username and a password. Even though passwords can be relatively secure if they
are long, unique, and randomly generated, *they might still be compromised*, for
example, by phishing attacks. This is especially problematic for site
administrators, whose accounts can access and modify site settings, forum posts, user information,
and other sensitive data.

As such, we would like to *lessen the impact in case of compromised
administrator credentials*. One way to achieve that goal is through the use of
*Two-Factor Authentication*, which is readily available as an official NodeBB
plugin, `nodebb-plugin-2factor` @nodebb-plugin-2factor, and is installed by
default, though it has to be enabled manually from the administrator panel.

Instead of pursuing this approach, however, we *decided to support Passkeys*, a
new secure passwordless authentication method developed by the FIDO Alliance, based on
public-key cryptography @fido-passkeys. Passkeys rely on an _authenticator_, which might be a secure chip on the user's device (e.g., a mobile phone) or a separate hardware authentication device (such as a security key, like a YubiKey). This authenticator holds private keys for each associated passkey and performs the necessary cryptographic operations to securely identify the user to a _relying party_, such as the NodeBB website: the relying party generates a challenge which the authenticator cryptographically signs, enabling the relying party to verify that the provided challenge response has been signed by the private key associated with the public key that was mapped to the user during registration.

Using passkeys also counts as two-factor authentication,
completely replacing combinations such as a password + one-time passwords (OTP), since they are
validated on-device with biometrics or a PIN code, therefore requiring both a "something you have" factor and a "something you are"/"something you know" factor. They are also phishing
resistant, which neither passwords nor OTP are, due to their cryptographic
nature: the private key is never sent to the server, and the browser validates
that the origin matches the expected value before forwarding the authentication
response. Furthermore, they are also more convenient because users do not have to
remember passwords, and each passkey is only used in a single site. Additionally,
passkeys obsolete the need for users to enter their username, since the authentication challenge response
also includes a unique identifier of the user associated with the passkey, and websites store mappings between users and their registered passkey public keys.

All of these properties make passkeys a very compelling option for secure
authentication. As such, we came to the conclusion that adding passkey support to NodeBB would be the most effective way of mitigating situations where administrator users' passwords are compromised.

The downside for passkeys is that support is still being rolled out, which means not every device and operating system supports creating, storing, and using passkeys @passkeys-devices. This is also true for the NodeBB landscape in particular, where there is still no NodeBB plugin for passkeys @nodebb-passkeys, due to the technology being so new, so we had to develop our own. Fortunately, the hardware
security keys support in the two-factor plugin for NodeBB @nodebb-plugin-2factor
is very similar to what we want to implement, so we used it as inspiration for this
proof-of-concept.

We extended our `Dockerfile` to copy the plugin's files into the container and automatically install it to NodeBB, so an administrator only needs to activate the plugin in the Admin Control Panel ("Admin" > "Extend" > "Plugins" > "`nodebb-plugin-passkeys`" > "Activate" > "Confirm" > "Rebuild & Restart" > "Confirm").

This simple procedure will instantly enable all users site-wide to register a passkey to their account, by accessing "Settings" > "Passkeys", allowing them to opt-in to a more secure experience. After registering a passkey, users can use it to sign into the website using the "Login with a Passkey" button shown on the regular login page, under "Alternative Logins". In order to support the login flow, we implemented a custom login strategy in accordance with `passport`'s specification @passport. Our plugin supplies this strategy to NodeBB, which invokes it when it is necessary to direct, validate, or support a user sign-in process.

There is a plethora of different parameters to tune in relation to WebAuthn @w3c-webauthn (the W3C standard supporting passkeys) operations, so we had to make certain design decisions in accordance with what we believed to be best in terms of security, feasibility, and user experience. Of these design choices, we point out:

- We require both user presence and user verification for an authentication attempt to be successful, ensuring that the authenticator makes use of a second authentication factor (i.e., prompts for a PIN code, biometric credentials, or another equivalent method);
- In order to simplify the passkey registration process, and to limit the amount of personal identifying information provided to us, we do not require any form of authenticator attestation by a Certificate Authority;
- We carefully selected which algorithms @cose-algos to accept, and in which order of preference, having settled on ECDSA, then RSASSA-PSS, and then RSASSA-PKCS1-v1_5, and for each of those suites preferring algorithms using SHA-512, then SHA-384, and then SHA-256. Originally we planned on listing COSE algorithm `-8`, EdDSA, as our preferential algorithm, but one of our dependencies @fido2-lib does not yet support it.

Moreover, we implemented a *Per-Group Passwordless Enforcement* feature that allows administrators (through "Admin" > "Plugins" > "Passkeys") to configure passwordless requirements for specific groups of users (such as the `administrators` group, or even all `registered-users`). Any groups selected using this feature will require its members to register a passkey if they have not already (users cannot view any pages or perform any action until they do), and members of such a group can no longer use their password to login after they have registered a passkey, therefore being forced to always login using a passkey, which significantly improves security as outlined above. We believe this feature is essential to help further the site's security, and our implementation supporting enforcement based on arbitrary groups gives administrators enormous flexibility. Evidently, to solve this specific #smallcaps[Unauthorized Administration] problem for this project, we recommend enabling passwordless enforcement for the `administrators` group.

// TODO
//
// explain how registration/login flows work
// talk about forcing passkeys for administrators
// difficulties: talk about the lack of documentation/libraries, as well as similarities between security keys, which makes it difficult to find information online
// maybe add more sources
// talk about 2FA plugin (basically just give step-by-step on how to enable it and set admin group)

#pagebreak()
= Group Members

== Diogo Correia

Diogo already had prior experience with Docker and JavaScript, which was a
valuable skill in this project. Along with #link(<rafael>)[Rafael], he worked on
the #link(<unauthorized-admin>)[Unauthorized Administration]
task, deliberating on what was the best course of action for solving the problem at
hands. It was first decided that we would implement two-factor authentication,
but upon finding out that the plugin already existed, and that a solution only
included clicking on a few buttons in the web interface, Diogo decided to
suggest *passkeys* as an alternative solution.

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
== Neil Prabhu

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

// TODO 1 page

#pagebreak()
== Yannik Tausch

// TODO 1 page

#pagebreak()
#show bibliography: set heading(numbering: "1.")
#bibliography("references.yml", title: "References")
