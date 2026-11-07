db.t.insertOne({_id: 1, a: 1});
printjson(db.t.findOneAndReplace({_id: 1}, {b: 2}, {returnDocument: "after"}));
db.t.findOne()
