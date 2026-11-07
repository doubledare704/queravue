db.t.insertOne({_id: 1, a: 1, b: 1});
print(db.t.createIndex({a: 1}));
print(db.t.createIndex({a: -1, b: 1}, {name: "custom"}));
print(db.t.getIndexes().map(function (i) { return i.name; }).sort().join(","));
db.t.dropIndex("a_1");
db.t.getIndexes().length
