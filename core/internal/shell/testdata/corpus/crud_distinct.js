db.t.insertMany([{_id: 1, k: "x"}, {_id: 2, k: "y"}, {_id: 3, k: "x"}]);
db.t.distinct("k").sort()
