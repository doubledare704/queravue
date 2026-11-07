db.t.insertMany([{_id: 1, a: 1}, {_id: 2, a: 2}]);
db.t.createIndex({a: 1});
db.t.find({a: {$gte: 1}}).hint({a: 1}).sort({a: 1}).toArray().length
