db.t.insertMany([{_id: 1, name: "b", age: 3}, {_id: 2, name: "a", age: 4}]);
db.t.find({}, {name: 1, _id: 0}).sort({name: 1}).toArray()
