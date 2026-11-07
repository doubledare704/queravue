db.t.insertMany([{_id: 1, k: MinKey()}, {_id: 2, k: MaxKey()}, {_id: 3, k: 1}]);
db.t.find().sort({k: 1}).toArray()
