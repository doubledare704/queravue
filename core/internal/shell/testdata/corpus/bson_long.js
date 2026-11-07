db.t.insertOne({_id: 1, big: NumberLong("9007199254740993"), small: NumberLong(5)});
var d = db.t.findOne();
printjson(d);
print(d.big.toString());
d.small.toNumber() + 1
