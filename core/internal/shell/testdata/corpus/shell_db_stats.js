db.t.insertOne({_id: 1});
var s = db.stats();
print(s.db);
s.collections >= 1
