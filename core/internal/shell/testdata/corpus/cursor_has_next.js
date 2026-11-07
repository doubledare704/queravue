db.t.insertMany([{_id: 1}, {_id: 2}]);
var c = db.t.find().sort({_id: 1});
print(c.hasNext());
printjson(c.next());
printjson(c.next());
c.hasNext()
