db.t.insertMany([{_id: 1}, {_id: 3}, {_id: 2}]);
db.t.find().sort({_id: -1}).toArray()
