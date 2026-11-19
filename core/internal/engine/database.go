package engine

// DefaultDatabaser is implemented by connections that have a default
// database, such as the database in a MongoDB connection string. Empty means
// none was configured.
type DefaultDatabaser interface {
	DefaultDatabase() string
}
