package mongosql

import (
	"encoding/json"
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/doubledare704/queravue/core/internal/engine/mongo"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

var plainCollectionName = regexp.MustCompile(`^[A-Za-z][A-Za-z0-9_]*$`)

// Names a shell database object answers itself instead of returning a collection.
var shellDatabaseMembers = map[string]bool{
	"getName": true, "getSiblingDB": true, "getCollection": true, "runCommand": true, "adminCommand": true,
	"getCollectionNames": true, "stats": true, "version": true, "serverStatus": true, "createCollection": true,
	"dropDatabase": true, "constructor": true, "hasOwnProperty": true, "isPrototypeOf": true,
	"propertyIsEnumerable": true, "toLocaleString": true, "toString": true, "valueOf": true,
}

func findResponse(database, collection string, spec findSpec) (*queravuev1.TranslateMongoSqlResponse, error) {
	filter, err := mongo.CanonicalEJSON(spec.filter)
	if err != nil {
		return nil, err
	}
	projection, err := optionalEJSON(spec.projection)
	if err != nil {
		return nil, err
	}
	sort, err := optionalEJSON(spec.sort)
	if err != nil {
		return nil, err
	}
	var code strings.Builder
	code.WriteString(collectionExpression(database, collection))
	code.WriteString(".find(" + filter)
	if projection != "" {
		code.WriteString(", " + projection)
	}
	code.WriteString(")")
	if sort != "" {
		code.WriteString(".sort(" + sort + ")")
	}
	if spec.skip > 0 {
		code.WriteString(".skip(" + strconv.FormatUint(spec.skip, 10) + ")")
	}
	if spec.limit != nil {
		code.WriteString(".limit(" + strconv.FormatUint(*spec.limit, 10) + ")")
	}
	return &queravuev1.TranslateMongoSqlResponse{
		Database:        database,
		Collection:      collection,
		Kind:            queravuev1.MongoSqlResultKind_MONGO_SQL_RESULT_KIND_FIND,
		FilterEjson:     filter,
		ProjectionEjson: projection,
		SortEjson:       sort,
		Skip:            spec.skip,
		Limit:           spec.limit,
		ShellCode:       code.String(),
	}, nil
}

func aggregateResponse(database, collection string, stages []bson.D) (*queravuev1.TranslateMongoSqlResponse, error) {
	encoded := make([]string, len(stages))
	for i, stage := range stages {
		text, err := mongo.CanonicalEJSON(stage)
		if err != nil {
			return nil, err
		}
		encoded[i] = text
	}
	pipeline := "[" + strings.Join(encoded, ",") + "]"
	return &queravuev1.TranslateMongoSqlResponse{
		Database:      database,
		Collection:    collection,
		Kind:          queravuev1.MongoSqlResultKind_MONGO_SQL_RESULT_KIND_AGGREGATE,
		PipelineEjson: pipeline,
		ShellCode:     collectionExpression(database, collection) + ".aggregate(" + pipeline + ")",
	}, nil
}

func optionalEJSON(doc bson.D) (string, error) {
	if len(doc) == 0 {
		return "", nil
	}
	return mongo.CanonicalEJSON(doc)
}

func collectionExpression(database, collection string) string {
	db := "db.getSiblingDB(" + jsString(database) + ")"
	if plainCollectionName.MatchString(collection) && !shellDatabaseMembers[collection] {
		return db + "." + collection
	}
	return fmt.Sprintf("%s.getCollection(%s)", db, jsString(collection))
}

func jsString(s string) string {
	b, err := json.Marshal(s)
	if err != nil {
		return `""`
	}
	return string(b)
}
