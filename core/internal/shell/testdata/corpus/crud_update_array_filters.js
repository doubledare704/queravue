db.t.insertOne({_id: 1, grades: [{s: 80}, {s: 95}, {s: 70}]});
db.t.updateOne({_id: 1}, {$set: {"grades.$[g].pass": true}}, {arrayFilters: [{"g.s": {$gte: 80}}]});
db.t.findOne()
