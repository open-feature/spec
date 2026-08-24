# Provider Conformance Assets

Test assets for the provider conformance suite described in [Appendix F](../../appendix-f-provider-conformance.md).

These validate a **provider** against a real backend. For assets that validate an **SDK**, see [`../gherkin/`](../gherkin/README.md) and [Appendix B](../../appendix-b-gherkin-suites.md).

## Contents

| Path | What it is |
| --- | --- |
| [`gherkin/evaluation.feature`](./gherkin/evaluation.feature) | resolving each type with the right value, variant and reason |
| [`gherkin/errors.feature`](./gherkin/errors.feature) | the type-mismatch matrix and the unknown-flag case |
| [`gherkin/events.feature`](./gherkin/events.feature) | configuration change, and the stale/ready transition across an outage |
| [`gherkin/lifecycle.feature`](./gherkin/lifecycle.feature) | initialisation against a healthy backend and against an unreachable one |
| [`flags/canonical-flags.json`](./flags/canonical-flags.json) | the flag set every scenario assumes |
| [`openapi/control-api.yaml`](./openapi/control-api.yaml) | the HTTP surface a backend under test must expose |

## These three travel together

A feature file that evaluates `boolean-flag` is meaningless without the flag definition, and a disconnect scenario is meaningless without the control endpoint that produces the disconnect. Changing one without the others breaks the suite in every language at once.

## Two properties that are load-bearing

- **`missing-flag` must not exist** in the flag set. Its absence is what the `FLAG_NOT_FOUND` scenario tests. Seeding it turns that scenario green for the wrong reason.
- **No flag has targeting rules.** Every scenario expects reason `STATIC`, because the suite tests the provider's mapping of a backend response, not the backend's evaluation logic.

The flag set is expressed in the flagd flag-definition format because that is the only widely implemented vendor-neutral format today. The format is not what matters — the keys, types, variant names and resolved values are. Seed them however your backend seeds flags.
