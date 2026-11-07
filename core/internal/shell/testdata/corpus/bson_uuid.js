db.t.insertOne({_id: UUID("0123456789abcdef0123456789abcdef"), tag: "u"});
var d = db.t.findOne();
print(d._id.toString());
printjson(d)
