# Provider Conformance Assets

Test assets for the provider conformance suite described in [Appendix F](../../appendix-f-provider-conformance.md).

These validate a **provider** against a real backend. For assets that validate an **SDK**, see [`../gherkin/`](../gherkin/README.md) and [Appendix B](../../appendix-b-gherkin-suites.md).

## Contents

| Path | What it is |
| --- | --- |
| [`gherkin/evaluation.feature`](./gherkin/evaluation.feature) | resolving each type with the right value and reason; the variant where the backend names one; falsy values; integer precision |
| [`gherkin/errors.feature`](./gherkin/errors.feature) | the type-mismatch matrix, numeric coercion and the unknown-flag case |
| [`gherkin/events.feature`](./gherkin/events.feature) | configuration change, and the stale/ready transition across an outage |
| [`gherkin/lifecycle.feature`](./gherkin/lifecycle.feature) | initialisation against a healthy backend and against an unreachable one; shutdown |
| [`gherkin/metadata.feature`](./gherkin/metadata.feature) | the provider identifies itself by name |
| [`flags/canonical-flags.json`](./flags/canonical-flags.json) | the flag set every scenario assumes |
| [`openapi/control-api.yaml`](./openapi/control-api.yaml) | the HTTP surface a backend under test must expose |
| [`report/conformance-report.schema.json`](./report/conformance-report.schema.json) | the shape of a machine-readable conformance report |

## These three travel together

A feature file that evaluates `boolean-flag` is meaningless without the flag definition, and a disconnect scenario is meaningless without the control endpoint that produces the disconnect. Changing one without the others breaks the suite in every language at once.

## Four properties that are load-bearing

- **`missing-flag` must not exist** in the flag set. Its absence is what the `FLAG_NOT_FOUND` scenario tests. Seeding it turns that scenario green for the wrong reason.
- **Only `targeting-key-flag` has a targeting rule.** Every other enabled flag resolves to its default variant whatever the evaluation context, which is what lets the untargeted scenarios expect reason `STATIC`. Seeding targeting onto any other flag breaks them in every language at once. Its rule is specified by behaviour — resolve `hit` when the targeting key is exactly `5c3d8535-f81a-4478-a6d3-afaa4d51199e`, `miss` otherwise — so express it however your backend expresses targeting. The flag, its variants and the uuid are the ones [flagd-testbed's `targeting.feature`](https://github.com/open-feature/flagd-testbed) already uses, on the same reasoning as the zero flags: a backend serving that harness already serves this.
- **`boolean-zero-flag`, `integer-zero-flag` and `string-zero-flag` resolve to falsy values on purpose.** A seeding step that treats `false`, `0` or `""` as "unset" and drops them turns the falsy-value scenarios into `FLAG_NOT_FOUND` failures that look like provider defects. These names, and their `zero`/`non-zero` variants, are the ones [Appendix B's SDK suite](../gherkin/test-flags.json) already uses, so a backend serving that flag set already serves these.
- **The four `disabled-*` flags are the only ones whose state is not `ENABLED`.** They resolve to nothing — the caller's default stands in, and no variant is named. Every other scenario assumes a flag serves its own value, so enabling one of these, or disabling anything else, breaks that assumption silently. Names, variants and values are [flagd-testbed's own](https://github.com/open-feature/flagd-testbed), from `flags/disabled-flags.json`.
- **`integral-float-flag` is a float and `huge-integer-flag` is an integer.** Seeding `10.0` as `10` makes the lossless-coercion scenario pass without coercing; seeding `9007199254740991` through a float rounds it.

The flag set is expressed in the flagd flag-definition format because that is the only widely implemented vendor-neutral format today. The format is not what matters — the keys, types, variant names and resolved values are. Seed them however your backend seeds flags.

## Consuming from Go

This directory is also a Go module, `github.com/open-feature/spec/specification/assets/provider-tck`, whose only content is an `embed.FS` of the artifacts above. The Go conformance suite depends on it instead of vendoring a copy: a Go module ships as a zip of the VCS tree, in which a git submodule is only a gitlink, so an embed from a submodule would arrive empty for anyone running `go get`. The other languages build from a working tree and keep using the submodule; `go.mod` and `embed.go` are inert for them.

A consumer pins a release the usual way:

```console
go get github.com/open-feature/spec/specification/assets/provider-tck@v0.1.0
```

## Releases

These assets are released independently of the specification, by [release-please](../../../release-please-config.json). A nested Go module is tagged with its path as a prefix, so a release is tagged `specification/assets/provider-tck/vX.Y.Z` — the same shape as `providers/flagd/v0.6.0` in the SDK contrib repositories. The specification's own `vX.Y.Z` tags are cut by release-please too, from a separate release pull request that excludes this directory, and do not apply here; nothing about the two numbering schemes is related.

What a bump means is not the usual thing, because this is a test suite rather than a library:

- **A minor bump may turn a passing suite red.** Adding a scenario, or tightening one, raises the bar a provider has to clear. Nothing changed on the adopter's side and their build can still go from green to red, which is the point of adopting a conformance suite and is why new scenarios are released as minors rather than as patches.
- **A patch bump cannot.** Patches are editorial: a clarified scenario name, a comment, a fix to something that never ran.

So pinning is not optional bookkeeping. A suite that floats on the latest assets cannot distinguish a regression in the provider from a new question being asked of it.

## Consuming from the other three languages

Java, Python and JavaScript reach these files through a git submodule of this repository, because a JAR, a wheel and an npm package are all built from a working tree where the submodule is present. A submodule can track the release tag rather than a bare commit, which makes the pin readable in review:

```ini
[submodule "spec"]
  path = tools/provider-tck/spec
  url = https://github.com/open-feature/spec.git
  branch = specification/assets/provider-tck/v0.1.0
```

The recorded gitlink is still a commit, so `git submodule update --init` and `actions/checkout` with `submodules: recursive` behave exactly as before. Only `git submodule update --remote` is affected, which resolves `branch` and will report that the tag is not a branch — do not use it on a submodule pinned this way.

## Keeping a pin current

Both forms are updatable by [Renovate](https://docs.renovatebot.com), so an adopting repository is told about a new release rather than discovering it:

- Go: the `gomod` manager, on by default, raises a PR for a new `specification/assets/provider-tck/vX.Y.Z`.
- The submodule: the `git-submodules` manager, which is opt-in and reads the tag out of `branch` above.

```json
{
  "git-submodules": { "enabled": true }
}
```

Let those PRs run the suite. A red one is the report that conformance narrowed, and reading it is the work — which is why it is worth *not* automerging these.
