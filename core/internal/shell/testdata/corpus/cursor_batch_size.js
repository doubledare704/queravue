var docs = [];
for (var i = 0; i < 25; i++) docs.push({_id: i});
db.t.insertMany(docs);
db.t.find().batchSize(4).toArray().length
