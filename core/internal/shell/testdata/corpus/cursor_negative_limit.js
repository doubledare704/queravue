db.t.insertMany([{_id: 1}, {_id: 2}, {_id: 3}]);
db.t.find().sort({_id: 1}).limit(-2).toArray()
