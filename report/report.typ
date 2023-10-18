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

// TODO 2 pages

#pagebreak()
== Unauthorized Access

// TODO 2 pages

#pagebreak()
== Unauthorized Administration <unauthorized-admin>

// TODO 2 pages

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

// TODO 1 page

#pagebreak()
== Rafael Oliveira <rafael>

// TODO 1 page

#pagebreak()
== Yannik Tausch

// TODO 1 page

