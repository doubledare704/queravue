db.t.insertOne({_id: 1, tags: ["a", "b", "c", "a"]});
db.t.updateOne({_id: 1}, {$pull: {tags: "a"}});
db.t.updateOne({_id: 1}, {$addToSet: {tags: "d"}});
db.t.updateOne({_id: 1}, {$pop: {tags: 1}});
db.t.findOne()
