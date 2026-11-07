db.t.insertOne({_id: 1, a: 1, b: 2});
printjson(db.t.replaceOne({_id: 1}, {c: 3}));
db.t.findOne({_id: 1})
