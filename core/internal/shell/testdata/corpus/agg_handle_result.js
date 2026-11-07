db.t.insertMany([{_id: 1, k: "a"}, {_id: 2, k: "b"}]);
db.t.aggregate([{$sort: {_id: 1}}, {$addFields: {upper: {$toUpper: "$k"}}}])
