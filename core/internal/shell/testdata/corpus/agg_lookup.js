db.users.insertMany([{_id: 1, name: "ada"}, {_id: 2, name: "bob"}]);
db.orders.insertMany([{_id: 10, user: 1, total: 5}, {_id: 11, user: 1, total: 7}]);
db.users.aggregate([{$lookup: {from: "orders", localField: "_id", foreignField: "user", as: "orders"}}, {$project: {name: 1, orders: {$size: "$orders"}}}, {$sort: {_id: 1}}]).toArray()
