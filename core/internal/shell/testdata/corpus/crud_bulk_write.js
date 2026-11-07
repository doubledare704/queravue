db.t.insertOne({_id: 1, n: 1});
printjson(db.t.bulkWrite([
  {insertOne: {document: {_id: 2, n: 2}}},
  {updateOne: {filter: {_id: 1}, update: {$set: {n: 10}}}},
  {deleteOne: {filter: {_id: 2}}},
  {replaceOne: {filter: {_id: 3}, replacement: {_id: 3, n: 3}, upsert: true}}
]));
db.t.find().sort({_id: 1}).toArray()
