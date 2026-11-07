db.t.insertOne({_id: 1});
try { db.t.insertOne({_id: 1}); } catch (e) { print(e.name); print(e.code); }
