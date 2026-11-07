db.t.insertMany([{_id: 1, a: {b: {c: 1}}}, {_id: 2, a: {b: {c: 2}}}]);
db.t.find({"a.b.c": 2}).toArray()
