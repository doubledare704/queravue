var other = db.getSiblingDB("$DB_sibling");
other.t.insertOne({_id: 1});
print(other.getName());
print(other.t.countDocuments());
db.t.countDocuments()
