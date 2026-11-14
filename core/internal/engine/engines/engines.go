// Package engines wires every built-in engine into a registry. It lives apart
// from package engine so engine implementations can import engine without a
// cycle.
package engines

import (
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/clickhouse"
	"github.com/doubledare704/queravue/core/internal/engine/mongo"
	"github.com/doubledare704/queravue/core/internal/engine/mssql"
	"github.com/doubledare704/queravue/core/internal/engine/mysql"
	"github.com/doubledare704/queravue/core/internal/engine/oracle"
	"github.com/doubledare704/queravue/core/internal/engine/postgres"
	"github.com/doubledare704/queravue/core/internal/engine/redis"
	"github.com/doubledare704/queravue/core/internal/engine/sqlite"
)

// All returns the built-in engines in display order, then those a build tag
// enables.
func All() []engine.Engine {
	return append(builtIn(), taggedEngines()...)
}

func builtIn() []engine.Engine {
	return []engine.Engine{
		postgres.New(postgres.VariantPostgres),
		postgres.New(postgres.VariantCockroach),
		mysql.New(mysql.VariantMySQL),
		mysql.New(mysql.VariantMariaDB),
		mysql.New(mysql.VariantTiDB),
		mssql.New(),
		oracle.New(),
		clickhouse.New(),
		mongo.New(mongo.VariantMongoDB),
		mongo.New(mongo.VariantCosmos),
		mongo.New(mongo.VariantDocumentDB),
		redis.New(redis.VariantRedis),
		redis.New(redis.VariantValkey),
		sqlite.New(),
	}
}

// Registry returns a registry with All engines.
func Registry() (*engine.Registry, error) {
	return engine.NewRegistry(All()...)
}
