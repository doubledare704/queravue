db.t.insertOne({_id: 1, at: ISODate("2021-03-04T05:06:07.089Z"), day: ISODate("2021-03-04")});
var d = db.t.findOne();
print(d.at.getTime());
print(d.day.toISOString());
printjson(d)
