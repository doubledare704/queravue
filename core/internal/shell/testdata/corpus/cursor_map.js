db.t.insertMany([{_id: 1, n: 1}, {_id: 2, n: 2}]);
db.t.find().sort({_id: 1}).map(function (d) { return d.n * 10; }).toArray()
