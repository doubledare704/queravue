db.t.insertOne({_id: 1, list: [ISODate("2020-01-01T00:00:00Z"), NumberLong(2), {deep: {oid: ObjectId("5f1d7f3e9b1c2a0012345678")}}], nothing: null});
printjson(db.t.findOne())
