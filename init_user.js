const crypto = require('crypto');
const pwd = crypto.randomBytes(32).toString('base64');
const dbNodebb = db.getSiblingDB("nodebb");
print("\n\n\n\n\n\n\n\n\n\n\n")
print("#################################################################");
print("#                                                               #");
print(`# nodebb password: ${pwd} #`);
print("#                                                               #");
print("#################################################################");
print("\n\n\n\n\n\n\n\n\n\n\n")
dbNodebb.createUser({ user: "nodebb", pwd, roles: [ "readWrite" ] });
dbNodebb.grantRolesToUser("nodebb", [ { role: "clusterMonitor", db: "admin" } ]);
