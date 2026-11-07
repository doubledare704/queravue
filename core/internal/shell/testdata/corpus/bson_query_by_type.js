db.t.insertMany([{_id: 1, v: NumberLong(5)}, {_id: 2, v: 5}, {_id: 3, v: "5"}]);
db.t.find({v: {$type: "string"}}).toArray();
db.t.find({v: 5}).sort({_id: 1}).toArray().length
