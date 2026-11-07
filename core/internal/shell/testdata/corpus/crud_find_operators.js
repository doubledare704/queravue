db.t.insertMany([{_id: 1, n: 5}, {_id: 2, n: 10}, {_id: 3, n: 15}, {_id: 4, n: 20}]);
print(db.t.find({n: {$gt: 5, $lte: 15}}).toArray().length);
print(db.t.find({n: {$in: [5, 20]}}).toArray().length);
print(db.t.find({$or: [{n: 5}, {n: 20}]}).toArray().length);
db.t.find({n: {$not: {$gt: 5}}}).toArray()
