printjson(db.createCollection("made"));
print(db.getCollectionNames().indexOf("made") >= 0);
print(db.made.drop());
db.made.drop()
