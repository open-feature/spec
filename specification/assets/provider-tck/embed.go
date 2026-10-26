// Package providertck carries the provider conformance assets as a Go module,
// so a Go conformance suite can depend on a specific revision of them the way
// it depends on any other module.
//
// The other language suites consume this directory through a git submodule,
// which works because a wheel or a JAR is built from a working tree where the
// submodule is present. A Go module is distributed as a zip built from the
// VCS tree, where a submodule is only a gitlink and its files are absent, so
// the Go suite would otherwise have to commit a copy of every artifact and
// police it against drift. Publishing the artifacts as a module removes the
// copy: the consumer pins a commit or tag in its go.mod, the Go checksum
// database makes that revision immutable, and the embedded bytes are the same
// bytes every other language reads out of the submodule.
//
// The module contains no code beyond this file and has no dependencies. It is
// inert for every consumer that is not Go. See
// https://github.com/open-feature/spec/issues/417.
package providertck

import "embed"

// FS holds the conformance artifacts, keyed by their path relative to this
// directory, so that they are addressed here exactly as they are documented:
//
//	gherkin/*.feature          the canonical scenarios
//	flags/canonical-flags.json the flag set those scenarios assume
//	openapi/control-api.yaml   the HTTP surface a backend under test exposes
//
// The README and .gitattributes beside them are not artifacts and are not
// embedded.
//
//go:embed gherkin/*.feature
//go:embed flags/canonical-flags.json
//go:embed openapi/control-api.yaml
var FS embed.FS
