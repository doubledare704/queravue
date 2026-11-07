var r = db.t.insertOne({_id: 1, name: "ada"});
printjson(r);
db.t.countDocuments()
