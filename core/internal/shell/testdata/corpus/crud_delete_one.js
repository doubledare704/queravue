db.t.insertMany([{_id: 1, k: 1}, {_id: 2, k: 1}]);
printjson(db.t.deleteOne({k: 1}));
db.t.countDocuments()
