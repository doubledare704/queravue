use $DB_other
print(db.getName());
db.t.insertOne({_id: 1});
db.t.countDocuments()
