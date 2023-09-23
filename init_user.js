db = db.getSiblingDB("nodebb");
db.createUser( { user: "nodebb", pwd: "s8M8ndjq9NIUG76b65", roles: [ "readWrite" ] } );
db.grantRolesToUser("nodebb",[{ role: "clusterMonitor", db: "admin" }]);
