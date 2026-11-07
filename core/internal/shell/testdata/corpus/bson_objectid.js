db.t.insertOne({_id: ObjectId("5f1d7f3e9b1c2a0012345678")});
var d = db.t.findOne();
print(d._id.toString());
print(d._id.getTimestamp().toISOString());
printjson(d)
