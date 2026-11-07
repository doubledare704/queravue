db.t.insertMany([{_id: 1, k: "a"}, {_id: 2, k: "b"}, {_id: 3, k: "a"}]);
db.t.find({k: "a"}).sort({_id: -1})
