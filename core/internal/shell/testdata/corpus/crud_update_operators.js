db.t.insertOne({_id: 1, a: 1, b: 2, tags: ["x"], n: 5});
db.t.updateOne({_id: 1}, {$set: {c: 3}, $unset: {b: ""}, $push: {tags: "y"}, $max: {n: 9}, $mul: {a: 4}});
db.t.findOne()
