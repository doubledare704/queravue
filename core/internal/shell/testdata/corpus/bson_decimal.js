db.t.insertOne({_id: 1, price: NumberDecimal("19.990")});
var d = db.t.findOne();
printjson(d);
d.price.toString()
