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

| | Appendix B | Appendix F |
| --- | --- | --- |
| Subject under test | the **SDK** | the **provider** |
| Harness | an [in-memory provider](./appendix-a-included-utilities.md#in-memory-provider) | the provider under test, against a real backend |
| Answers | does this SDK implement the Evaluation API, hooks and events correctly? | does this provider map its backend onto the provider contract correctly? |

They are complementary. An SDK passing Appendix B and a provider passing Appendix F are different
claims, and a language needs both suites to make both.

## What it tests, and what it does not

**In scope — the provider contract:**

- mapping backend responses onto typed resolution details: value, variant, reason, error code, and
  no error message on a normal evaluation
- the values most often mistaken for an absence — `false`, `0` and `""` — resolving as values
- integer precision: a 32-bit maximum for every language, and 2^53 − 1 where the accessor allows it
- keeping the integer and float types distinct rather than coercing between them
- error handling: a type mismatch and an unknown flag return the code default, report the right
  error code, and never throw
- identity: a non-empty metadata name
- lifecycle: reaching `READY`, settling into `ERROR` against an unreachable backend, and a shutdown
  that is idempotent, reversible by initialising again, and prompt when the backend is gone
- events: `PROVIDER_READY`, `PROVIDER_ERROR`, `PROVIDER_STALE`, `PROVIDER_CONFIGURATION_CHANGED`
- that a signalled configuration change is actually **applied** on re-evaluation, not merely
  signalled

**Out of scope:**

- **Backend evaluation logic**, bucketing and rule-language correctness. Every flag in the canonical
  set except `targeting-key-flag` resolves to its default variant whatever the context, so what is
  under test is the provider's mapping of a response, not the backend's decision. It carries
  the one rule, and it is there to prove the context reached the backend rather than to test how the
  backend evaluated it — which is why the rule is stated as behaviour and not as a syntax.
- **The provider↔backend wire protocol.** How a provider talks to its backend is its own business.
- **SDK behaviour.** That is Appendix B.

## The three artifacts

Conformance rests on three files, and they **travel together by necessity**. A feature file that
evaluates `boolean-flag` is meaningless without the flag definition, and a disconnect scenario is
meaningless without the control endpoint that produces the disconnect. Changing one without the
others breaks the suite in every language at once.

| Artifact | Location | What it defines |
| --- | --- | --- |
| Gherkin scenarios | [`assets/provider-tck/gherkin/`](./assets/provider-tck/README.md) | the test cases themselves |
| Canonical flag set | [`assets/provider-tck/flags/canonical-flags.json`](./assets/provider-tck/flags/canonical-flags.json) | the flags those cases assume |
| Control API | [`assets/provider-tck/openapi/control-api.yaml`](./assets/provider-tck/openapi/control-api.yaml) | what a backend under test must expose |

### Gherkin scenarios

Five feature files:

- [`evaluation.feature`](./assets/provider-tck/gherkin/evaluation.feature) — resolving each type with
  the right value, variant and reason; falsy values; integer precision
- [`errors.feature`](./assets/provider-tck/gherkin/errors.feature) — the type-mismatch matrix, numeric
  coercion and the unknown-flag case
- [`events.feature`](./assets/provider-tck/gherkin/events.feature) — configuration change, and the
  stale/ready transition across an outage
- [`lifecycle.feature`](./assets/provider-tck/gherkin/lifecycle.feature) — initialisation against a
  healthy backend and against an unreachable one; shutdown
- [`metadata.feature`](./assets/provider-tck/gherkin/metadata.feature) — the provider identifies
  itself by name

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
- **Only `targeting-key-flag` has a targeting rule.** Every other flag resolves to its default variant
  whatever the evaluation context, which is what lets the untargeted scenarios expect reason
  `STATIC`. Seeding targeting onto any other flag breaks them in every language at once.

### The control API

Scenarios need to change flags and simulate outages, and they need to do it identically across
vendors. The control API is a small HTTP surface the backend under test exposes for that purpose:

| Endpoint | Required | Purpose |
| --- | --- | --- |
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
| --- | --- |
| `@events` | emits lifecycle events at all |
| `@lifecycle` | performs an initialisation that reaches its backend, with an observable outcome |
| `@stale` | enters `STALE` and emits `PROVIDER_STALE` on backend loss |
| `@configuration-change` | detects configuration changes and emits `PROVIDER_CONFIGURATION_CHANGED` |
| `@object` | supports structured flag values |
| `@variants` | names the variant it resolved, which [Requirement 2.2.4](./sections/02-providers.md#requirement-224) makes a `SHOULD` and `types.md` types as optional |
| `@unavailable` | reports an error state instead of hanging against a dead backend |
| `@numeric-coercion` | coerces between integer and float only when lossless, else `TYPE_MISMATCH` |
| `@large-integers` | resolves integers up to 2^53 − 1 exactly; undeclarable where the SDK's integer accessor is 32-bit |
| `@reinitialization` | can be initialised again after `shutdown`, which [Requirement 2.5.2](./sections/02-providers.md#requirement-252) permits rather than requires |
| `@targeting` | resolves a flag differently for a matching evaluation context |
| `@caching` | reserved; **not declarable** -- no scenarios yet |

Untagged scenarios are mandatory and always run.

A reserved tag is documented so the vocabulary has a place for the capability when scenarios exist,
but it **must not be declared** and must not appear in a conformance report's declaration. No
scenario carries it, so declaring it cannot be verified, cannot produce a skip, and tells a reader
only that something was claimed and nothing examined -- the vacuous conformance claim this whole
vocabulary exists to prevent. `@caching` is the only reserved tag left.

This is easy to reintroduce by accident rather than by intent. An adopter who declares "every
capability except X" picks up every reserved tag on the way past, which is exactly how one
implementation came to report `@targeting` and `@caching` as declared -- back when both were
reserved. An implementation offering a "declare everything" convenience should exclude reserved tags
from it, and should tell an adopter who names one directly rather than passing it silently into a
report.

`@lifecycle` and `@events` are deliberately separate, and conflating them is the mistake this
vocabulary exists to prevent. Every SDK synthesises `PROVIDER_READY` for a provider that has no
initialisation step -- the Go SDK's comment says so outright, *"a provider without state handling
capability can be assumed to be ready immediately"* -- so a provider with no lifecycle passes the
readiness scenario without demonstrating anything, exactly as a no-op provider would. A stateless
HTTP provider such as OFREP is the common case: it observably emits nothing of its own and cannot
fail initialisation, yet its client still reports `READY`. Such a provider declares neither tag, and
the lifecycle scenarios are reported as skipped rather than passing vacuously.

`@reinitialization` is separate from `@lifecycle` for a subtler reason, and it is worth recording how
it came to be separate. [Requirement 2.5.2](./sections/02-providers.md#requirement-252) says a
provider **SHOULD** revert to its uninitialized state after `shutdown`, and its supporting text adds
that *"some providers **may** allow reinitialization from this state"*. Reuse is therefore permitted,
not required. A provider that releases its client on shutdown and refuses to be started again is
exercising a choice the specification offers it.

The scenario was originally untagged, on the reading that reverting to the uninitialized state "is
observable as exactly one thing — it can be initialized again and then serves flags". That inference
does not hold, and the cost of it was concrete: a provider making a permitted choice was reported as
failing conformance, and the failure was on its way to being filed as a defect against the
implementation. A false failure is the mirror image of a vacuous pass, and this appendix cares about
both.

Reverting the state is not separately observable either — a provider that reverts but refuses reuse
presents exactly as one that did neither — so a gated reuse scenario is the only assertion the
requirement admits. It is worth keeping for the providers that do offer reuse, because releasing the
client on shutdown while leaving an initialised flag set is easy to write and leaves the provider
evaluating against a closed connection rather than failing outright.

The design rule behind this: **a conformance suite that quietly goes green on scenarios it did not
run is worse than no suite at all** — and, learned later and at some cost, one that reports a
permitted choice as a failure is not much better. A TCK implementation must report unsupported
capabilities as skipped and surface the reason, not silently pass or silently omit them; and a
scenario must be gated whenever the behaviour it asserts is one the specification allows a provider
to decline.

### Rules for declaring

The four rules below are stated rather than implied because each was discovered by four
implementations answering the same question differently. They are what makes two reports comparable.

**A scenario is gated by every capability tag that applies to it, including tags inherited from its
feature.** Tags compose: a tag on a `Feature` applies to every scenario in it, and a scenario
carrying its own tag is gated by both. A scenario runs only when **all** of its capabilities are
declared, and is otherwise reported as skipped naming one of the undeclared ones. This matters for
reading a result: `lifecycle.feature` carries `@lifecycle` at feature level, so the re-initialization
scenario inside it needs `@lifecycle` *and* `@reinitialization`, and declaring only the second leaves
it skipped — a declaration that looks satisfied and examines nothing.

**Declare a capability only on evidence from running the suite, never from reading the provider's
source.** Source inspection is unreliable here in both directions, and demonstrably so: one
provider's shutdown explicitly reverts its own initialised flag, which reads as support for reuse,
while the transport underneath cannot be restarted and initialization fails on a deadline. Another
closes its client with nothing visibly reconstructing it, which reads as a refusal, and works. Run
the cycle.

**A `knownDeviations` entry is for a behaviour the provider is required to have and does not.** The
requirement must be a numbered `MUST`, or a rule the implementation has bound itself to elsewhere —
a vendor's own architecture decision, say. Where the specification permits the choice, withholding
the capability *is* the honest report and a deviation entry would assert a defect that does not
exist. A false failure is the mirror image of a vacuous pass, and a reader cannot tell them apart
from the outside. When a scenario fails, find the numbered requirement before concluding anything:
check whether it is a `MUST`, a `SHOULD`, or explicitly optional.

**The `reason` field is the deliberate exception, and it is stated here so it is a decision rather
than an oversight.** [Requirement 2.2.5](./sections/02-providers.md#requirement-225) is also a
`SHOULD`, and it goes further than 2.2.4 does: it lets a provider populate the field with one of the
listed values *"or some other string indicating the semantic reason for the returned flag value"*.
The suite nonetheless requires a reason, and requires a specific one, in every scenario that asserts
it. A provider whose backend reports vendor-specific reason strings will fail those scenarios.

That is a narrowing of the specification, and it is accepted for now because the reason is the
suite's cheapest diagnosis of a whole class of silent failure: a provider that quietly falls back to
the code default reports a different reason, and the assertion names the problem where a value
assertion alone only says the number was wrong. Gating it would mean a second capability, a second
set of scenarios to keep in step, and a declaration nearly every provider would make anyway.

A reader comparing reports should therefore treat a reason failure differently from a value failure:
the value assertions rest on `MUST` requirements, the reason assertions rest on a house rule. If a
conformant provider is failed by one, that is this suite's narrowing and not that provider's defect
-- and the right response is to revisit this decision, not to record a deviation against the
provider.

`@variants` is the clearest case, and it was found the hard way. Every evaluation scenario asserted
a variant, which reads as obviously correct until a backend with no variant concept for a plain flag
is put under test: its evaluation response carries no such key, the provider never receives one, and
no seeding can produce one. Ten scenarios failed a conformant provider for something its author
could not fix, and nothing could be recorded as a known deviation because there was no capability to
hang one on. [Requirement 2.2.4](./sections/02-providers.md#requirement-224) is a `SHOULD` and
`types.md` types the field as optional; the suite was asserting a `MUST` neither of them states.

**Emit `knownDeviations` only when there is at least one.** An empty array and an absent field are
not the same claim: stating none asserts that deviations were considered and none found, which no
suite can know on the adopter's behalf. Omit the field when the list is empty, and never synthesise
an empty one.

`@numeric-coercion` deserves a note, because it is the one capability here that **the specification
does not define**, and readers should not mistake it for one that does.

OpenFeature has a single numeric type, deliberately: `number` is
[*"a numeric value of unspecified type or size"*](./types.md#number), and implementation languages **may**
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

Both halves of the rule have scenarios. The lossy half asks for `float-flag` (`0.5`) as an integer
and expects `TYPE_MISMATCH`; the lossless half asks for `integral-float-flag` (`10.0`) as an integer
and for `integer-flag` (`10`) as a float, and expects both to succeed. A provider declaring the tag
must satisfy all three — rejecting every float is an easy way to pass the first, and the other two
are what stop it. A provider whose SDK has a single numeric type, such as JavaScript, cannot
distinguish the cases at all, so it leaves the tag undeclared and the scenarios are reported as
skipped with that reason.

**Where a capability cannot hold in a language, this appendix is where that is recorded** — not a
field in every report. `@numeric-coercion` in a single-numeric-type language and `@large-integers` on
a 32-bit accessor are properties of the SDK, true of every provider written against it and for as
long as the accessor is what it is. Stating them here says it once; a per-report field would restate
a language fact on every provider's behalf, and would still say nothing in a run where no scenario
carried the tag.

That leaves one skip, carrying its reason, as the whole mechanism. A results payload does not need a
second status to distinguish "undeclared" from "cannot apply": both are skips, the reason says which,
and the scenario's own tags say what was being asked. Splitting them into separate statuses, or into
a parallel declaration field, multiplies the vocabulary that four implementations have to agree on
without telling a reader anything the reason does not.

**Accessor width** is the related property the ADR distinguishes, and it is modelled separately
because it is a property of the SDK rather than of the provider. Every language's integer accessor
can ask for 2^31 − 1, so that precision scenario is untagged. Only some can ask for 2^53 − 1: Go's
`ResolveIntValue` is `int64`, but Java's accessor is a 32-bit `Integer`, and a provider cannot
resolve a value the accessor has no room for. That scenario carries `@large-integers`, which a
provider on a 32-bit accessor leaves undeclared. Nothing above 2^53 − 1 is asked for: JavaScript
cannot represent it, and what a provider owes a value that does not fit the requested accessor is
the open question in [open-feature/spec#430](https://github.com/open-feature/spec/issues/430).

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

## Extending the suite

A provider often has behaviour this specification does not describe — flagd's fractional targeting,
a vendor's own segment rules — and no way to test it inside this suite. The alternative an adopter
reaches for is a parallel harness that reimplements provider registration, the readiness wait and
the per-scenario backend reset, and then drifts from the one here. So a TCK implementation **MAY**
offer an extension point: the adopter supplies feature files and step definitions, and they run
inside the same suite, against the same backend, in the same lifecycle.

The mechanism is the implementation's own — a classpath scan, a `conftest.py`, two configuration
fields — and this appendix does not prescribe one. What it does prescribe is the four properties that
keep an extension from quietly becoming a conformance claim.

**Extension scenarios must be distinguishable from canonical ones.** A results payload that mixes
them with no way to tell which is which lets an adopter's own passing scenarios flatter the
conformance result. Partitioning by path is enough, and it is what a consumer reads to separate the
two:

- a canonical feature is identified by its path **relative to this asset directory** —
  `gherkin/errors.feature`, not a path relative to the repository root;
- an extension mounts under the reserved prefix **`extensions/`**.

Both are stated exactly because a phrasing that merely implied them produced three different answers
in four implementations. "The path it has in this repository" is the phrasing that did it, and it is
wrong in a way worth recording: these assets are also consumed as a released Go module, where the
module root *is* this directory and nothing inside it knows or should know where the directory sits
in a repository. `gherkin/errors.feature` is the only form every consumer can produce from what it
actually has.

Compare on the **path component**, after any URI scheme. A runner that resolves features from a
classpath or a bundle legitimately reports `classpath:gherkin/errors.feature`; the scheme belongs to
the runner and the results format, neither of which this appendix defines, and stripping it is the
consumer's job rather than the implementation's.

**An extension must not shadow a canonical scenario.** The same partition provides this: an
extension file cannot occupy a canonical path, so it can add questions but never replace one.

**Extension scenarios must never satisfy a canonical scenario.** An adopter's feature is an addition
to the canonical set, not a substitute for part of it. A rule under which supplying enough scenarios
of your own made the canonical ones optional would defeat the point of having a canonical set.

**A run that did not execute the canonical set in full must fail.** This is the one that needs
stating because it is not obvious, and because it was found by accident rather than by design: a
test selector matching a single scenario name produced a green suite and a **well-formed conformance
report describing one scenario out of the whole canonical set**. A mis-wired extension
filesystem does the same.
There is no field in the report a consumer could read to notice — the schema is closed and the
envelope carries no expected count — so failing the run is the only lever the implementation has.

Two details of that check are worth recording, because both are easy to get wrong:

- **The expectation must come from the same parser the runner uses**, not a second one written for
  the check. A parser of the implementation's own will disagree with the runner about exactly the
  cases that matter — an `Examples` block carrying its own tags, scenarios nested in a `Rule` — and
  the expectation has to be what a full run would actually have produced.
- **A capability-gated skip is not a gap.** The scenario ran the gate and is reported as skipped with
  its reason, so the question was put and declined. Treating that as a gap would force every provider
  to declare every capability, which is the opposite of what the vocabulary is for.

## Reference implementation

The first implementation is `tools/provider-tck` in
[open-feature/java-sdk-contrib](https://github.com/open-feature/java-sdk-contrib), adopted by the
flagd provider for both its RPC and in-process resolvers. It is in review alongside this appendix.

## Open questions

This appendix is a proof of concept. Known gaps, all of which affect every language equally and so
belong here rather than in any one implementation:

- **Evaluation context passthrough, beyond the targeting key.** `targeting-key-flag` resolves differently
  for a matching context, so a provider that drops the context is caught by the resolved value
  itself — no echo operation needed for the basic case, which is how the `@targeting` scenarios
  work. What is still unverified is that the *whole* context arrives intact: a provider that
  forwards the targeting key and silently discards every other attribute passes. Asserting that
  needs either an echo operation on the control API, something like `GET /last-evaluation` returning
  the request the backend last received, or a second flag whose rule keys on a custom attribute.
  The latter is cheaper and worth doing first, since attributes are where dropping is most likely.
- **Setting and removing individual flags.** The control API can reset to a baseline and mutate one
  designated flag. Finer-grained flag manipulation would need new endpoints.
- **Caching.** Whether a stale provider keeps serving last-known values during an outage depends on
  whether it holds a local copy of the ruleset. The `@caching` tag is reserved; no scenarios yet.
- **Coverage of the numbered requirements.** Mapped against
  [the provider requirements](./sections/02-providers.md), leaving out 2.8.5.1 (it constrains the SDK)
  and 2.2.8.1 (a language-binding property, not observable at runtime), the suite covers 10 of the
  14 `MUST` requirements in scope, all 5 `SHOULD` — 2.2.4 only for a provider declaring `@variants`
  — and 1 of 6 `MAY`. The `MUST` gaps are 2.3.1 (the provider hook mechanism, a compile-time
  property in typed languages with little to observe at runtime), 2.2.10 (flag metadata structure,
  blocked with 2.2.9 on the canonical flag set defining
  none), 2.4.4 (a domain-scoped provider accepts its bound domain, which is as much SDK as provider
  behaviour) and 2.8.4 (`PROVIDER_CONTEXT_CHANGED`). The last is the largest hole: context
  reconciliation is where a provider is most likely to serve values computed for the *previous*
  context, and the failure is silent. It wants its own capability tag, and until the control API has
  an echo operation a scenario can show only that reconciliation was signalled, not that the values
  that follow are the new context's.
- **Normative status.** Nothing in this appendix is currently expressed as a numbered requirement.
  Whether the control API contract and the capability vocabulary should become normative sections is
  a decision for the TSC.
