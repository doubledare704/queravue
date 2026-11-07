db.t.insertOne({_id: 1});
var c = db.t.find();
c.hasNext();
c.limit(1)
