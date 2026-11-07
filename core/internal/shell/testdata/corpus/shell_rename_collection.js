db.old.insertOne({_id: 1});
db.old.renameCollection("renamed");
print(db.getCollectionNames().join(","));
db.renamed.countDocuments()
