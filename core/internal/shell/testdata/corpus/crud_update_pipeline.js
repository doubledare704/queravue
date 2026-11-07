db.t.insertOne({_id: 1, a: 2, b: 3});
db.t.updateOne({_id: 1}, [{$set: {sum: {$add: ["$a", "$b"]}}}]);
db.t.findOne()
