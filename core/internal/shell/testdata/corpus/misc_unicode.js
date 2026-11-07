db.t.insertOne({_id: 1, name: "héllo wörld ✓ 日本語"});
db.t.findOne({name: /wörld/})
