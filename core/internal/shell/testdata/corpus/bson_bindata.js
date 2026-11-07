db.t.insertOne({_id: 1, raw: BinData(0, "aGVsbG8="), custom: BinData(128, "AQID")});
var d = db.t.findOne();
print(d.raw.hex());
print(d.custom.length());
printjson(d)
