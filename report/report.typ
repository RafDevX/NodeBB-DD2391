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

In today's digital landscape, data security is paramount. Database leakage and
corruption refers to the unauthorized access, exposure, and tampering of a
database's content. Specifically for our scenario, the default configuration of
the database and NodeBB (a popular forum software) might be insecure, making it
vulnerable to attacks.

Unauthorized access to the database can lead to data exposure. This means that
sensitive information stored within the database, such as user credentials,
personal data, posts, and other sensitive content, could be accessed by
malicious actors. This data could be used for various malicious purposes, such
as identity theft, spam, or even blackmail. Furthermore, if attackers gain
access to the database, they can modify or delete data. This can result in the
corruption of the forum's content, erasing posts, changing user permissions, or
even defacing the website. Such actions can damage the reputation of the forum
and disrupt its normal operation.

Data leakage can also result in significant privacy violations, potentially
exposing the personal information of users, which may have legal and ethical
ramifications. Users' trust in the forum and its operators can be severely
undermined. If the forum is used for commercial purposes, a database breach can
lead to financial losses. For example, if user payment information is stored in
the database, it could be compromised, resulting in fraudulent transactions and
financial theft. Lastly, a database breach can damage the reputation of both the
forum and its administrators. Users may lose trust in the platform, leading to a
decrease in user engagement, decreased traffic, and potentially a loss of
revenue.

=== Chosen Countermeasures

1. _Deployment within isolated Docker Network_: The NodeBB application will be
  deployed within an isolated Docker network, ensuring that the database container
  and the host machine are not within direct reach.

2. _Randomized Database Password_: A randomized, complex password will be used for
  the database access. This ensures that even if an attacker gains access to the
  Docker environment, they won't be able to connect to the database without
  knowing the password.

=== Reasoning for the Countermeasures

The chosen countermeasure addresses the security concerns by leveraging the
inherent benefits of Docker and implementing strong access control:

1. _Isolation_: By deploying the application within an isolated Docker network, we
  take advantage of Docker's bridged networks and network namespaces, effectively
  preventing direct access to containers from the host machine. This means that an
  attacker on the host machine won't be able to access the database container
  directly.

2. _Randomized Password_: Using a randomized database password adds an additional
  layer of security. Even if an attacker manages to compromise the Docker
  environment or obtain access to configuration files, they will not be able to
  access the database without knowing the complex, randomized password.

=== Implementation of the Countermeasure

The implementation of this countermeasure involved several steps:

Step 1: Setting Up Docker Compose Stack

1. _Docker Installation_: Ensured that Docker is installed on the host machine.

2. _Docker Compose Configuration_: Created a Docker Compose configuration file that
  defines the services for NodeBB and the database. Also ensured that the database
  service is not exposed to the host network, and only accessible within the
  Docker network.

Step 2: Randomized Database Password

1. _Password Generation_: Generated a strong, randomized database password upon
  initial deployment.

2. _Database Configuration_: Modified the NodeBB configuration to use the
  randomized database password for database connections. This involved updating
  the configuration files and environment variables.

Step 3: Testing and Verification

1. _Testing_: Verified that the NodeBB application functions correctly with the set
  database configurations.

Step 4: Continuous Monitoring

In practice, our chosen countermeasures should ideally be supplemented by:

1. _Security Scanning_: Conduct security scans and penetration tests to ensure that
  there are no vulnerabilities or misconfigurations.

2. _Logging and Monitoring_: Set up logging and monitoring to detect any suspicious
  activity or unauthorized access attempts.

3. _Regular Password Rotation_: Implement a policy for regular password rotation to
  maintain the security of the database.

=== Difficulties and Solutions

During the implementation of these countermeasures, we encountered a few
challenges, and here's how we overcame them:

1. _Configuration Complexity_: Configuring Docker and managing Docker Compose
  stacks was quite complex, and we had to rely on documentation and online
  resources. Perhaps we could have used container orchestration tools like
  Kubernetes for more advanced control if we were actually deploying the software
  in production.

2. _Compatibility Issues_: We discovered compatibility issues between the chosen
  database management system and NodeBB within the Docker environment. We had to
  troubleshoot these compatibility issues by consulting relevant documentation and
  forums.

3. _Lack of Documentation_: We noticed that there was a lack of documentation for
  setting up NodeBB with Docker, and the docker-compose template in the repository
  was found to be outdated.

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
== Rafael Oliveira

// TODO 1 page

#pagebreak()
== Yannik Tausch

// TODO 1 page

