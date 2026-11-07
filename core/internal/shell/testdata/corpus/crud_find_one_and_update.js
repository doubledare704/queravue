db.t.insertOne({_id: 1, n: 1});
printjson(db.t.findOneAndUpdate({_id: 1}, {$inc: {n: 1}}));
printjson(db.t.findOneAndUpdate({_id: 1}, {$inc: {n: 1}}, {returnDocument: "after"}));
db.t.findOneAndUpdate({_id: 7}, {$set: {n: 1}})
