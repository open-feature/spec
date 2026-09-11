---
id: appendix-f
title: "Appendix F: Provider Conformance (TCK)"
description: A language-agnostic conformance suite for validating OpenFeature providers
sidebar_position: 7
---

# Appendix F: Provider Conformance (TCK)

[![experimental](https://img.shields.io/static/v1?label=Status&message=experimental&color=orange)](https://github.com/open-feature/spec/tree/main/specification#experimental)

> **Status: proof of concept.** The artifacts in this appendix are under active development and are
> not yet normative. The scenario set is a representative subset covering each architectural
> mechanism once, not exhaustive coverage. Breaking changes should be expected.

OpenFeature's central promise is that swapping providers does not change application behaviour.
Nothing currently verifies that. Every provider tests itself differently, against its own backend,
with its own harness — so "implements the provider contract" is an unverified claim, and a
behavioural difference between two providers is discovered by the application that trips over it.

This appendix defines a **provider conformance suite**: a shared set of scenarios, a shared flag set,
and a shared way to manipulate a backend under test, so that the same conformance question can be
asked of every provider in every language and get comparable answers.

## Relationship to Appendix B

[Appendix B](./appendix-b-gherkin-suites.md) also contains Gherkin, and the distinction matters:

|  | Appendix B | Appendix F |
|---|---|---|
| Subject under test | the **SDK** | the **provider** |
| Harness | an [in-memory provider](./appendix-a-included-utilities.md#in-memory-provider) | the provider under test, against a real backend |
| Answers | does this SDK implement the Evaluation API, hooks and events correctly? | does this provider map its backend onto the provider contract correctly? |

They are complementary. An SDK passing Appendix B and a provider passing Appendix F are different
claims, and a language needs both suites to make both.

## What it tests, and what it does not

**In scope — the provider contract:**

- mapping backend responses onto typed resolution details: value, variant, reason, error code
- keeping the integer and float types distinct rather than coercing between them
- error handling: a type mismatch and an unknown flag return the code default, report the right
  error code, and never throw
- lifecycle: reaching `READY`, and settling into `ERROR` against an unreachable backend
- events: `PROVIDER_READY`, `PROVIDER_ERROR`, `PROVIDER_STALE`, `PROVIDER_CONFIGURATION_CHANGED`
- that a signalled configuration change is actually **applied** on re-evaluation, not merely
  signalled

**Out of scope:**

- **Backend evaluation logic**, targeting and bucketing correctness. Every flag in the canonical set
  resolves to its default variant with no targeting involved, so what is under test is the
  provider's mapping of a response, not the backend's decision.
- **The provider↔backend wire protocol.** How a provider talks to its backend is its own business.
- **SDK behaviour.** That is Appendix B.

## The three artifacts

Conformance rests on three files, and they **travel together by necessity**. A feature file that
evaluates `boolean-flag` is meaningless without the flag definition, and a disconnect scenario is
meaningless without the control endpoint that produces the disconnect. Changing one without the
others breaks the suite in every language at once.

| Artifact | Location | What it defines |
|---|---|---|
| Gherkin scenarios | [`assets/provider-tck/gherkin/`](./assets/provider-tck/README.md) | the test cases themselves |
| Canonical flag set | [`assets/provider-tck/flags/canonical-flags.json`](./assets/provider-tck/flags/canonical-flags.json) | the flags those cases assume |
| Control API | [`assets/provider-tck/openapi/control-api.yaml`](./assets/provider-tck/openapi/control-api.yaml) | what a backend under test must expose |

### Gherkin scenarios

Four feature files:

- [`evaluation.feature`](./assets/provider-tck/gherkin/evaluation.feature) — resolving each type with
  the right value, variant and reason
- [`errors.feature`](./assets/provider-tck/gherkin/errors.feature) — the type-mismatch matrix and the
  unknown-flag case
- [`events.feature`](./assets/provider-tck/gherkin/events.feature) — configuration change, and the
  stale/ready transition across an outage
- [`lifecycle.feature`](./assets/provider-tck/gherkin/lifecycle.feature) — initialisation against a
  healthy backend and against an unreachable one

The step vocabulary is inherited from the
[flagd test harness](https://github.com/open-feature/test-harness) wherever it was already
provider-neutral, so an existing suite ports with a near-zero diff.

### The canonical flag set

A backend under test must serve an equivalent set under the configuration named `default`. The file
is expressed in the flagd flag-definition format because that is the only widely implemented
vendor-neutral format today — **the format is not what matters**, the keys, types, variant names and
resolved values are. Seed them however your backend seeds flags.

Two properties are load-bearing and easy to break by accident:

- **`missing-flag` must not exist.** Its absence is what the `FLAG_NOT_FOUND` scenario tests. Seeding
  it turns that scenario green for the wrong reason.
- **No flag has targeting rules.** Every scenario expects reason `STATIC`, because the suite tests
  the provider's mapping of a response, not the backend's decision.

### The control API

Scenarios need to change flags and simulate outages, and they need to do it identically across
vendors. The control API is a small HTTP surface the backend under test exposes for that purpose:

| Endpoint | Required | Purpose |
|---|---|---|
| `POST /start?config=<name>` | yes | start the backend, seeding flags to a named baseline |
| `POST /stop` | yes | make the backend unreachable |
| `POST /restart?seconds=<n>` | yes | simulate an outage of a bounded duration |
| `POST /change` | yes | mutate flag configuration so the provider observes a change |
| `POST /reset` | no | restore the baseline without an availability blip |
| `GET /healthz` | no | readiness of the control API |

See the [OpenAPI document](./assets/provider-tck/openapi/control-api.yaml) for the normative detail.

Two invariants are worth stating here because they are the ones a TCK implementation gets wrong:

- **No container is ever stopped or restarted between scenarios.** Unavailability is simulated
  *inside* the running stack. Container orchestrators assign host ports dynamically and cannot
  reliably preserve them across a restart, so restarting would silently invalidate every provider
  already pointed at the old port. The failure looks like a flaky provider.
- **Scenario isolation comes from the control API**, not from cycling the stack. The backend is
  started once per suite and reset before each scenario.

## Capabilities: how a provider says what it cannot do

Not every provider implements every optional part of the contract. A provider backed by a static
file has no meaningful notion of going stale; a provider without a streaming transport cannot emit
configuration-change events. Forcing those providers to fail scenarios they were never going to
satisfy makes the suite unadoptable.

Instead, each scenario that exercises an optional capability carries a **tag**, and a provider
declares which capabilities it supports. Scenarios whose tag is not declared are reported as
**skipped, with the reason** — never as passed.

| Tag | Meaning |
|---|---|
| `@events` | emits lifecycle events at all |
| `@lifecycle` | performs an initialisation that reaches its backend, with an observable outcome |
| `@stale` | enters `STALE` and emits `PROVIDER_STALE` on backend loss |
| `@configuration-change` | detects configuration changes and emits `PROVIDER_CONFIGURATION_CHANGED` |
| `@object` | supports structured flag values |
| `@unavailable` | reports an error state instead of hanging against a dead backend |
| `@numeric-coercion` | coerces between integer and float only when lossless, else `TYPE_MISMATCH` |
| `@targeting` | reserved; **not declarable** -- no scenarios yet |
| `@caching` | reserved; **not declarable** -- no scenarios yet |

Untagged scenarios are mandatory and always run.

A reserved tag is documented so the vocabulary has a place for the capability when scenarios exist,
but it **must not be declared** and must not appear in a conformance report's declaration. No
scenario carries it, so declaring it cannot be verified, cannot produce a skip, and tells a reader
only that something was claimed and nothing examined -- the vacuous conformance claim this whole
vocabulary exists to prevent.

This is easy to reintroduce by accident rather than by intent. An adopter who declares "every
capability except X" picks up every reserved tag on the way past, which is exactly how one
implementation came to report `@targeting` and `@caching` as declared. An implementation offering a
"declare everything" convenience should exclude reserved tags from it, and should tell an adopter who
names one directly rather than passing it silently into a report.

`@lifecycle` and `@events` are deliberately separate, and conflating them is the mistake this
vocabulary exists to prevent. Every SDK synthesises `PROVIDER_READY` for a provider that has no
initialisation step -- the Go SDK's comment says so outright, *"a provider without state handling
capability can be assumed to be ready immediately"* -- so a provider with no lifecycle passes the
readiness scenario without demonstrating anything, exactly as a no-op provider would. A stateless
HTTP provider such as OFREP is the common case: it observably emits nothing of its own and cannot
fail initialisation, yet its client still reports `READY`. Such a provider declares neither tag, and
the lifecycle scenarios are reported as skipped rather than passing vacuously.

The design rule behind this: **a conformance suite that quietly goes green on scenarios it did not
run is worse than no suite at all.** A TCK implementation must report unsupported capabilities as
skipped and surface the reason, not silently pass or silently omit them.

`@numeric-coercion` deserves a note, because it is the one capability here that **the specification
does not define**, and readers should not mistake it for one that does.

OpenFeature has a single numeric type, deliberately: `number` is
[*"a numeric value of unspecified type or size"*](../types.md), and implementation languages **may**
further differentiate between integers and floating point numbers *"as idioms dictate"*. Both the
client and provider requirements say "boolean, numeric, string, and structure" — one numeric type,
not two. Typed-language SDKs take up that idiom and expose two accessors anyway, and at that point
no requirement answers the obvious question: what must a provider do when a value does not fit the
accessor it was asked through? `0.5` requested as an integer is not a corner case, it is the ordinary
consequence of a two-accessor SDK over a one-type wire format. That gap is
[open-feature/spec#430](https://github.com/open-feature/spec/issues/430).

So the rule this tag is tested against is **borrowed, not normative**: lossless coercion is
permitted, lossy coercion must return `TYPE_MISMATCH`. An integral float such as `10.0` requested as
an integer must succeed; `0.5` must not. It comes from flagd's
[numeric coercion ADR](https://github.com/open-feature/flagd/blob/main/docs/architecture-decisions/numeric-coercion.md),
which is scoped to flagd's own implementations, and the tag took the ADR's name — it was
`@strict-numeric-typing` — because flagd's testbed is gaining `@numeric-coercion` scenarios and two
vocabularies for one observable property is worse than one borrowed name. **A provider that behaves
differently is not violating the specification**, and this suite must not be read as saying it is.

That is also why the capability is genuinely optional, rather than optional as a concession to a
known defect. An earlier draft of this appendix claimed the specification required the behaviour and
that not declaring the tag was "an admission of a known bug". That was wrong on the first count, and
therefore on the second.

What remains true is that the observed behaviour is bad for users: flagd narrows `0.5` to `0` with no
error code at all, in Go and in Java, in both resolvers, so an application receives a plausible value
and no signal. That is being fixed in
[open-feature/flagd#1996](https://github.com/open-feature/flagd/issues/1996). A provider withholding
this capability should say which it is — a deliberate choice, or a tracked defect — and a conformance
report has `knownDeviations` for the second.

Two further gaps, both open rather than fixed here:

- **The lossless case has no scenario.** Only the lossy half is tested, so a provider that wrongly
  rejects `10.0` as an integer passes. Closing it needs an integral float in the canonical flag set,
  which changes the flag set for every language at once.
- **Accessor width is not modelled.** The ADR distinguishes the width of a language's integer
  accessor — Go's `ResolveIntValue` is `int64` and so is the canonical `Long`, whereas a 32-bit
  accessor needs its own scenarios, which flagd's testbed tags `@int32-bounded`. This appendix has
  nothing equivalent, and it is a real source of cross-language disagreement.

## Implementing the suite in a language

A TCK implementation is the language-specific harness around these three artifacts. What it owns:

1. **Ship the artifacts.** Package the Gherkin, the flag set and the control API document with the
   library so that adopting providers need no submodule of their own.
2. **Implement the step definitions** against the language's OpenFeature SDK, using its Cucumber (or
   equivalent) runner.
3. **Own the lifecycle** — start the backend stack once, register the provider under test with the
   SDK, await events, tear down — so that an adopting provider writes no test infrastructure. If a
   provider author finds themselves adding lifecycle code, that is a defect in the TCK.
4. **Drive the backend only through the control API.** This is the part that makes the conformance
   claim portable: another language's TCK drives the same endpoints against the same stack and must
   get the same answers.
5. **Gate on capabilities** and report undeclared ones as skipped with a reason.
6. **Run scenarios serially.** Backend state is global to the suite; concurrent scenarios corrupt
   each other, and the symptom looks like a flaky provider rather than a broken test.

### Providers with no backend

An in-memory, environment-variable or file-based provider has nothing to connect to and no control
API to expose. A TCK implementation may offer an **in-process** control path for these, where flag
operations are direct manipulations of the provider's own state rather than HTTP calls.

This is a narrow allowance, and worth being explicit about, because it is the obvious thing to abuse.
**A provider with an external backend must use the control API.** Reaching into an external backend
from inside the test process — a test-only admin client, a shared database handle, a hook inside the
provider — produces a suite that passes while proving nothing, because the path it exercised is not
the path the contract describes.

Connection-dependent scenarios (`@stale`, `@unavailable`) have no meaning without a connection, so a
backend-less provider leaves those capabilities undeclared and they are skipped. An in-process
control path should **fail loudly** if a connection operation is reached anyway — that means a
capability was declared that the harness cannot back up, which is a test-configuration bug rather
than a provider defect.

## Reference implementation

The first implementation is `tools/provider-tck` in
[open-feature/java-sdk-contrib](https://github.com/open-feature/java-sdk-contrib), adopted by the
flagd provider for both its RPC and in-process resolvers. It is in review alongside this appendix.

## Open questions

This appendix is a proof of concept. Known gaps, all of which affect every language equally and so
belong here rather than in any one implementation:

- **Evaluation context passthrough.** The scenarios build evaluation contexts but cannot assert the
  context *reached* the backend intact. That needs an echo operation on the control API — something
  like `GET /last-evaluation` returning the request the backend last received. Until then a provider
  that silently drops the context passes. The `@targeting` tag is reserved for these scenarios.
- **Setting and removing individual flags.** The control API can reset to a baseline and mutate one
  designated flag. Finer-grained flag manipulation would need new endpoints.
- **Caching.** Whether a stale provider keeps serving last-known values during an outage depends on
  whether it holds a local copy of the ruleset. The `@caching` tag is reserved; no scenarios yet.
- **Hooks and flag metadata.** Not covered.
- **Normative status.** Nothing in this appendix is currently expressed as a numbered requirement.
  Whether the control API contract and the capability vocabulary should become normative sections is
  a decision for the TSC.
