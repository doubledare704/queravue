var doc = {a: 1, b: [true, null], c: "x"};
db.t.insertOne(Object.assign({_id: 1}, doc));
JSON.stringify(db.t.findOne())
