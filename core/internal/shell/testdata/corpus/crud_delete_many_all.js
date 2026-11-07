db.t.insertMany([{_id: 1}, {_id: 2}]);
printjson(db.t.deleteMany({}));
db.t.countDocuments()
