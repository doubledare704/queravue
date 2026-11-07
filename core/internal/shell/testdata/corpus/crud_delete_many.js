db.t.insertMany([{_id: 1, k: 1}, {_id: 2, k: 1}, {_id: 3, k: 2}]);
printjson(db.t.deleteMany({k: 1}));
db.t.find().toArray()
