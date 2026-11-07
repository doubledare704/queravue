db.t.insertMany([{_id: 1, name: "Alice"}, {_id: 2, name: "bob"}, {_id: 3, name: "alfred"}]);
db.t.find({name: /^al/i}).sort({_id: 1}).toArray()
