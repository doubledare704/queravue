db.t.insertOne({_id: 1, re: /ab+c/i});
var d = db.t.findOne();
print(d.re.source);
print(d.re.ignoreCase);
printjson(d)
