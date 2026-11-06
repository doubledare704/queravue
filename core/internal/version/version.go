// Package version holds build metadata for the core binary.
package version

// Version is the core's semantic version. Override at build time with
// -ldflags "-X github.com/doubledare704/queravue/core/internal/version.Version=1.2.3".
var Version = "0.1.0-dev"

// ProtocolVersion is the revision of the queravue.v1 contract this core
// implements. Bump it whenever RPCs are added.
const ProtocolVersion uint32 = 4
