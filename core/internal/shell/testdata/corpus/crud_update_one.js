db.t.insertMany([{_id: 1, n: 1}, {_id: 2, n: 1}]);
printjson(db.t.updateOne({n: 1}, {$set: {n: 2}}));
db.t.find().sort({_id: 1}).toArray()
