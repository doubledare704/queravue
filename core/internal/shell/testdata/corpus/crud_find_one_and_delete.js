db.t.insertMany([{_id: 1, n: 2}, {_id: 2, n: 1}]);
printjson(db.t.findOneAndDelete({}, {sort: {n: 1}}));
db.t.countDocuments()
