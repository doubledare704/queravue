db.t.insertOne({_id: 1});
var plan = db.t.find({_id: 1}).explain();
typeof plan.queryPlanner
