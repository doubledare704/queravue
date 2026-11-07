db.t.insertMany([{_id: 1}, {_id: 2}, {_id: 3}, {_id: 4}]);
print(db.t.find().count());
print(db.t.find().skip(1).limit(2).count());
db.t.find().skip(1).limit(2).size()
