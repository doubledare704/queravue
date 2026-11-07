var r = db.t.insertOne({a: 1});
print(typeof r.insertedId);
print(r.insertedId.toString().length);
db.t.findOne({_id: r.insertedId}).a
