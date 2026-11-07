db.t.insertMany([{_id: 1}, {_id: 2}, {_id: 3}, {_id: 4}, {_id: 5}]);
db.t.find().sort({_id: 1}).skip(1).limit(3).toArray()
