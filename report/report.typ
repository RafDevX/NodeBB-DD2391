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

== Database Leakage and Corruption

In today's digital landscape, data security is paramount. Database leakage and corruption refers to the unauthorized access, exposure, and tampering of a database's content. Specifically for our scenario, the default configuration of the database and NodeBB (a popular forum software) might be insecure, making it vulnerable to attacks.

Unauthorized access to the database can lead to data exposure. This means that sensitive information stored within the database, such as user credentials, personal data, posts, and other sensitive content, could be accessed by malicious actors. This data could be used for various malicious purposes, such as identity theft, spam, or even blackmail. Furthermore, if attackers gain access to the database, they can modify or delete data. This can result in the corruption of the forum's content, erasing posts, changing user permissions, or even defacing the website. Such actions can damage the reputation of the forum and disrupt its normal operation.

Data leakage can also result in significant privacy violations, potentially exposing the personal information of users, which may have legal and ethical ramifications. Users' trust in the forum and its operators can be severely undermined. If the forum is used for commercial purposes, a database breach can lead to financial losses. For example, if user payment information is stored in the database, it could be compromised, resulting in fraudulent transactions and financial theft. Lastly, a database breach can damage the reputation of both the forum and its administrators. Users may lose trust in the platform, leading to a decrease in user engagement, decreased traffic, and potentially a loss of revenue.

=== Chosen Countermeasures

1. _Deployment within Docker Compose Stack_: The NodeBB application will be deployed within a Docker Compose stack. This ensures that the database container is isolated from direct access from the host machine.

2. _Randomized Database Password_: A randomized, complex password will be used for the database access. This ensures that even if an attacker gains access to the Docker environment, they won't be able to connect to the database without knowing the password.

=== Reasoning for the Countermeasures

The chosen countermeasure addresses the security concerns by leveraging the inherent benefits of Docker and implementing strong access control:

1. _Isolation_: By deploying the application within a Docker Compose stack, we take advantage of Docker's network isolation. Docker uses bridged networks and network namespaces, effectively preventing direct access to containers from the host machine. This means that an attacker on the host machine won't be able to access the database container directly.

2. _Randomized Password_: Using a randomized database password adds an additional layer of security. Even if an attacker manages to compromise the Docker environment or obtain access to configuration files, they will not be able to access the database without knowing the complex, randomized password.

=== Implementation of the Countermeasure

The implementation of this countermeasure involves several steps:

Step 1: Set Up Docker Compose Stack

1. _Docker Installation_: Ensure Docker is installed on the host machine.

2. _Docker Compose Configuration_: Create a Docker Compose configuration file that defines the services for NodeBB and the database. Ensure that the database service is not exposed to the host network, and only accessible within the Docker network.

Step 2: Randomized Database Password

1. _Database Configuration_: Modify the NodeBB configuration to use the randomized database password for database connections. This may involve updating the configuration files, environment variables, or a secrets management tool, depending on your setup.

2. _Password Management_: Generate a strong, randomized password using a secure password manager or generator.

3. _Apply Changes_: Restart the NodeBB application to apply the new configuration with the randomized database password.

Step 3: Testing and Verification

1. _Testing_: Verify that the NodeBB application functions correctly with the new database configuration.

Step 4: Continuous Monitoring (in practice)

1. _Security Scanning_: Conduct security scans and penetration tests to ensure that there are no vulnerabilities or misconfigurations.


2. _Logging and Monitoring_: Set up logging and monitoring to detect any suspicious activity or unauthorized access attempts.

3. _Regular Password Rotation_: Implement a policy for regular password rotation to maintain the security of the database.

=== Difficulties and Solutions

During the implementation of these countermeasures, we encountered a few challenges, and here's how we overcame them:

1. _Configuration Complexity_: Configuring Docker and managing Docker Compose stacks was quite complex, and we had to rely on documentation and online resources. Perhaps we could have used container orchestration tools like Kubernetes for more advanced control if we were actually deploying the software in production.

2. _Compatibility Issues_: We discovered compatibility issues between the chosen database management system and NodeBB within the Docker environment. We had to troubleshoot these compatibility issues by consulting relevant documentation and forums.

#pagebreak()
== Unauthorized Access

// TODO 2 pages

#pagebreak()
== Unauthorized Administration

// TODO 2 pages

#pagebreak()
= Group Members

== Diogo Correia

// TODO 1 page

#pagebreak()
== Neil Prabhu

Before this project, I had a basic understanding of web applications and database management, but I had never encountered NodeBB. Similarly, Docker and containerization were tools/technologies that I had extremely limited experience in. Therefore, the learning curve was steep and required me to dive headfirst into technologies that were entirely new to me, but I was eager to embrace them.

One of the most valuable aspects of this journey was the opportunity to shadow other group members who had more experience with NodeBB and Docker. Through collaboration and learning from their expertise, I gained practical insights into these technologies. They shared their knowledge about configuring and deploying NodeBB within Docker Compose stacks, managing Docker networks, and maintaining containerized applications. As I encountered challenges during the implementation phase, I was fortunate to have experienced team members to turn to for guidance. I remember struggling with Docker network configurations and compatibility issues with the database management system, and it was through their mentorship that I gained a better understanding of how to overcome these hurdles.

Specifically, I was responsible for persisting the admin user so that every time we started the docker image, we didn't have to initialize and register the admin constantly.  I created a Docker volume or bind mount to store the NodeBB data, ensuring that the admin user data was saved there. Then, I configured the NodeBB application to reference this volume or bind mount for data storage, guaranteeing that the admin user's credentials were preserved between Docker container restarts. Consequently, whenever the Docker image was started, NodeBB loaded the persisted data from the volume or bind mount, ensuring that the admin user remained accessible without the need for repeated initialization and registration. Lastly, I was responsible for completing the _Database Leakage and Corruption_ chapter of this report.

#pagebreak()
== Rafael Oliveira

// TODO 1 page

#pagebreak()
== Yannik Tausch

// TODO 1 page

