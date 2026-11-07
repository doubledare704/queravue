db.t.insertOne({_id: 1, a: 1, b: NumberLong("2"), c: 1.5, d: "s"});
db.t.aggregate([{$project: {_id: 0, a: {$type: "$a"}, b: {$type: "$b"}, c: {$type: "$c"}, d: {$type: "$d"}}}]).toArray()
