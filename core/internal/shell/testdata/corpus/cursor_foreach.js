db.t.insertMany([{_id: 1, n: 1}, {_id: 2, n: 2}, {_id: 3, n: 3}]);
var total = 0;
db.t.find().forEach(function (d) { total += d.n; });
total
