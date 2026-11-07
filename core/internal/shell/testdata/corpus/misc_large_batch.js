var docs = [];
for (var i = 0; i < 2000; i++) docs.push({_id: i, n: i % 7});
db.t.insertMany(docs);
db.t.find({n: 3}).itcount()
