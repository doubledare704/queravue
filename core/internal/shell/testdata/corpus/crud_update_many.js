db.t.insertMany([{_id: 1, n: 1}, {_id: 2, n: 1}, {_id: 3, n: 5}]);
printjson(db.t.updateMany({n: 1}, {$inc: {n: 10}}));
db.t.find().sort({_id: 1}).toArray()
