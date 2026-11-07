db.t.insertOne({_id: 1, i: NumberInt(7), plain: 8, big: 3000000000});
db.t.aggregate([{$project: {_id: 0, i: {$type: "$i"}, plain: {$type: "$plain"}, big: {$type: "$big"}}}]).toArray()
