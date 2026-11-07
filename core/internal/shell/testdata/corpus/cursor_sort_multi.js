db.t.insertMany([{_id: 1, a: 1, b: 2}, {_id: 2, a: 1, b: 1}, {_id: 3, a: 0, b: 5}]);
db.t.find().sort({a: -1, b: 1}).toArray()
