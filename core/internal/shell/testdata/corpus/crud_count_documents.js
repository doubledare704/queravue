db.t.insertMany([{_id: 1, k: "x"}, {_id: 2, k: "x"}, {_id: 3, k: "y"}]);
print(db.t.countDocuments());
print(db.t.countDocuments({k: "x"}));
print(db.t.countDocuments({k: "z"}));
db.t.countDocuments({}, {limit: 2})
