db.t.insertMany([{_id: 1, k: "a", z: 1}, {_id: 2, k: "b", z: 2}]);
db.t.find({}, {z: 0}).sort({_id: 1}).skip(1)
