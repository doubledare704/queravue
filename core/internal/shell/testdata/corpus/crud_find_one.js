db.t.insertMany([{_id: 1, n: "a"}, {_id: 2, n: "b"}, {_id: 3, n: "c"}]);
db.t.findOne({_id: 2})
