db.t.insertOne({_id: 1, tags: ["a", "b"]});
db.t.aggregate([{$unwind: "$tags"}, {$project: {_id: 0, tags: 1}}]).toArray()
