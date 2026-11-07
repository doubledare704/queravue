db.t.insertMany([{_id: 1, k: "a", n: 1}, {_id: 2, k: "b", n: 5}, {_id: 3, k: "a", n: 3}]);
db.t.aggregate([{$match: {n: {$gt: 0}}}, {$group: {_id: "$k", total: {$sum: "$n"}, c: {$sum: 1}}}, {$sort: {_id: 1}}]).toArray()
