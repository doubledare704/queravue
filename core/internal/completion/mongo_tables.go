package completion

import "strings"

type described struct{ name, detail string }

func nameSet(list string) map[string]bool {
	set := map[string]bool{}
	for _, w := range strings.Fields(list) {
		set[w] = true
	}
	return set
}

var dbMethods = []described{
	{"getCollection", "(name)"}, {"getCollectionNames", "()"}, {"getCollectionInfos", "(filter)"}, {"getName", "()"},
	{"getSiblingDB", "(name)"}, {"runCommand", "(command)"}, {"adminCommand", "(command)"}, {"createCollection", "(name, options)"},
	{"createView", "(name, source, pipeline)"}, {"dropDatabase", "()"}, {"stats", "()"}, {"version", "()"},
	{"serverStatus", "()"}, {"currentOp", "()"}, {"killOp", "(opid)"}, {"hostInfo", "()"}, {"aggregate", "(pipeline)"}, {"watch", "(pipeline)"},
}

var dbMethodNames = func() map[string]bool {
	set := map[string]bool{}
	for _, m := range dbMethods {
		set[m.name] = true
	}
	return set
}()

var collectionMethods = []described{
	{"find", "(filter, projection)"}, {"findOne", "(filter, projection)"}, {"aggregate", "(pipeline)"},
	{"countDocuments", "(filter)"}, {"estimatedDocumentCount", "()"}, {"count", "(filter)"}, {"distinct", "(field, filter)"},
	{"insertOne", "(document)"}, {"insertMany", "(documents)"}, {"updateOne", "(filter, update)"}, {"updateMany", "(filter, update)"},
	{"replaceOne", "(filter, replacement)"}, {"deleteOne", "(filter)"}, {"deleteMany", "(filter)"},
	{"findOneAndUpdate", "(filter, update)"}, {"findOneAndDelete", "(filter)"}, {"findOneAndReplace", "(filter, replacement)"},
	{"bulkWrite", "(operations)"}, {"createIndex", "(keys, options)"}, {"createIndexes", "(specs)"}, {"dropIndex", "(name)"},
	{"dropIndexes", "()"}, {"getIndexes", "()"}, {"drop", "()"}, {"renameCollection", "(name)"}, {"stats", "()"},
	{"validate", "()"}, {"watch", "(pipeline)"}, {"explain", "(verbosity)"},
}

var cursorMethods = []described{
	{"sort", "(spec)"}, {"limit", "(n)"}, {"skip", "(n)"}, {"projection", "(spec)"}, {"hint", "(index)"},
	{"collation", "(options)"}, {"batchSize", "(n)"}, {"maxTimeMS", "(ms)"}, {"comment", "(text)"}, {"min", "(bounds)"},
	{"max", "(bounds)"}, {"returnKey", "(flag)"}, {"showRecordId", "()"}, {"allowDiskUse", "()"}, {"explain", "(verbosity)"},
	{"toArray", "()"}, {"forEach", "(fn)"}, {"map", "(fn)"}, {"hasNext", "()"}, {"next", "()"}, {"itcount", "()"},
	{"count", "()"}, {"size", "()"}, {"pretty", "()"}, {"close", "()"}, {"isClosed", "()"},
}

var shellGlobals = []described{
	{"db", "current database"}, {"ObjectId", "(hex)"}, {"ISODate", "(iso string)"}, {"NumberInt", "(n)"}, {"NumberLong", "(n)"},
	{"NumberDecimal", "(text)"}, {"UUID", "(text)"}, {"Date", "()"}, {"RegExp", "(pattern, flags)"}, {"print", "(value)"},
	{"printjson", "(value)"}, {"sleep", "(ms)"}, {"tojson", "(value)"},
}

var logicalOperators = []described{
	{"$and", "all conditions match"}, {"$or", "any condition matches"}, {"$nor", "no condition matches"},
	{"$expr", "aggregation expression"}, {"$text", "text search"}, {"$where", "JavaScript predicate"},
	{"$comment", "annotate the query"}, {"$jsonSchema", "validate against a schema"},
}

var fieldOperators = []described{
	{"$eq", "equals"}, {"$ne", "not equal"}, {"$gt", "greater than"}, {"$gte", "greater than or equal"}, {"$lt", "less than"},
	{"$lte", "less than or equal"}, {"$in", "in array"}, {"$nin", "not in array"}, {"$exists", "field is present"},
	{"$type", "BSON type"}, {"$regex", "regular expression"}, {"$options", "regex options"}, {"$not", "negate an operator"},
	{"$elemMatch", "an array element matches"}, {"$size", "array length"}, {"$all", "array has all values"},
	{"$mod", "modulo"}, {"$bitsAllSet", "all bits set"}, {"$bitsAnySet", "any bit set"}, {"$bitsAllClear", "all bits clear"},
	{"$bitsAnyClear", "any bit clear"}, {"$geoWithin", "inside a shape"}, {"$geoIntersects", "intersects a shape"},
	{"$near", "near a point"}, {"$nearSphere", "near a point on a sphere"},
}

var updateOperators = []described{
	{"$set", "set fields"}, {"$unset", "remove fields"}, {"$inc", "add to a number"}, {"$mul", "multiply a number"},
	{"$min", "keep the smaller"}, {"$max", "keep the larger"}, {"$rename", "rename a field"}, {"$setOnInsert", "set on upsert insert"},
	{"$currentDate", "set to now"}, {"$push", "append to an array"}, {"$addToSet", "append if missing"},
	{"$pull", "remove matching elements"}, {"$pop", "remove first or last element"}, {"$pullAll", "remove listed values"},
	{"$bit", "bitwise update"},
}

var updateFieldOperators = nameSet("$set $unset $inc $mul $min $max $rename $setOnInsert $currentDate $push $addToSet $pull $pop $pullAll $bit")

var pipelineStages = []described{
	{"$match", "filter documents"}, {"$group", "group and accumulate"}, {"$project", "shape documents"}, {"$sort", "order documents"},
	{"$limit", "keep the first n"}, {"$skip", "skip the first n"}, {"$unwind", "one document per array element"},
	{"$lookup", "join another collection"}, {"$addFields", "add fields"}, {"$set", "add fields"}, {"$unset", "remove fields"},
	{"$count", "count documents"}, {"$facet", "run several pipelines"}, {"$bucket", "group into ranges"},
	{"$bucketAuto", "group into automatic ranges"}, {"$sample", "random documents"}, {"$replaceRoot", "replace the document"},
	{"$replaceWith", "replace the document"}, {"$out", "write to a collection"}, {"$merge", "merge into a collection"},
	{"$graphLookup", "recursive lookup"}, {"$sortByCount", "group and count"}, {"$unionWith", "append another collection"},
	{"$redact", "restrict content"}, {"$geoNear", "order by distance"}, {"$densify", "fill gaps"}, {"$fill", "fill missing values"},
	{"$setWindowFields", "window functions"},
}

var accumulators = []described{
	{"$sum", "sum"}, {"$avg", "average"}, {"$min", "minimum"}, {"$max", "maximum"}, {"$first", "first value"},
	{"$last", "last value"}, {"$push", "collect into an array"}, {"$addToSet", "collect distinct values"}, {"$count", "count"},
	{"$stdDevPop", "population deviation"}, {"$stdDevSamp", "sample deviation"}, {"$top", "top by order"}, {"$bottom", "bottom by order"},
	{"$firstN", "first n values"}, {"$lastN", "last n values"}, {"$maxN", "n largest"}, {"$minN", "n smallest"},
	{"$mergeObjects", "merge documents"},
}

var lookupKeys = []described{
	{"from", "collection to join"}, {"localField", "field in this collection"}, {"foreignField", "field in the other collection"},
	{"as", "output array field"}, {"let", "variables for the pipeline"}, {"pipeline", "sub-pipeline"},
}

var unwindKeys = []described{
	{"path", "array field"}, {"includeArrayIndex", "output index field"}, {"preserveNullAndEmptyArrays", "keep empty arrays"},
}

var pathOnlyStages = nameSet("$project $addFields $set $unset $sort $sortByCount")
