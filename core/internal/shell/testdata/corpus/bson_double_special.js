db.t.insertOne({_id: 1, nan: NaN, inf: Infinity, ninf: -Infinity, half: 0.5, big: 1e300});
printjson(db.t.findOne())
