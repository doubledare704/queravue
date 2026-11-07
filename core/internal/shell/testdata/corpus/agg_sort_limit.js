db.t.insertMany([{_id: 1, n: 3}, {_id: 2, n: 1}, {_id: 3, n: 2}]);
db.t.aggregate([{$sort: {n: 1}}, {$limit: 2}, {$project: {_id: 0, n: 1}}]).toArray()
