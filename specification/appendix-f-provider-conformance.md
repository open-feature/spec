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

- mapping backend responses onto typed resolution details: value, variant, error code, and no error
  message on a normal evaluation; the resolution reason where a provider claims the standard
  vocabulary
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

## What an implementation must do

Every obligation this appendix places on a TCK implementation, in one place. Each links to the
section that explains it; the explanations are why, and none of them is a requirement.

Nothing here is numbered. The numbered requirements in this specification are the provider contract —
`2.2.1`, `2.4.1`, `5.1.1` — and this suite exists to test them. These are obligations on the *harness*,
and giving them numbers beside the ones they test would put two different kinds of claim in one
namespace.

**Artifacts and lifecycle** — [Implementing the suite in a language](#implementing-the-suite-in-a-language)

- Package the Gherkin, the flag set and the control API document with the library.
- Make it impossible to run against assets the build did not fetch.
- Own the lifecycle and the container stack, so an adopter writes no test infrastructure.
- Start the stack once per suite; never restart it.
- Wait for readiness by asking the control API, and never wait after a control call.
- Drive the backend only through the control API.
- Run scenarios serially.

**Capabilities** — [Capabilities](#capabilities-how-a-provider-says-what-it-cannot-do)

- Report a scenario gated on an undeclared capability as skipped with its reason, never as passed.
- Refuse a reserved capability, and refuse one the language's SDK cannot express.
- Fail the run when a reserved tag reaches a collected scenario, or when a declarable capability gates
  none.

**The runner** — [The runner](#the-runner)

- Use the timeout defaults, and let an adopter override each.
- Let an explicit `within {int}ms` take precedence over the event default.
- Register a fresh provider per scenario under a suite-derived domain, and replace it at the end.

**Extension** — [Extending the suite](#extending-the-suite)

- Offer an extension point running in the same lifecycle phase.
- Expose the client and provider under test to extension steps.
- Keep extension scenarios distinguishable from canonical ones.

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

Six feature files:

- [`evaluation.feature`](./assets/provider-tck/gherkin/evaluation.feature) — resolving each type with
  the right value and variant; falsy values; integer precision
- [`reason.feature`](./assets/provider-tck/gherkin/reason.feature) — the standard resolution reasons,
  gated as a whole on `@standard-reasons`
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

Two steps were not neutral and were renamed, which is the whole of the diff: `Given a stable flagd
provider` became `Given a stable provider`, and its unavailable counterpart the same. They are named
here so that an implementer porting from the flagd harness knows the two places their existing step
definitions will not match, and so that "wherever it was already provider-neutral" can be checked
rather than taken on trust.

### The canonical flag set

A backend under test must serve an equivalent set under the configuration named `default`. The file
is expressed in the flagd flag-definition format because that is the only widely implemented
vendor-neutral format today — **the format is not what matters**, the keys, types, variant names and
resolved values are. Seed them however your backend seeds flags.

Two properties are load-bearing and easy to break by accident:

- **`missing-flag` must not exist.** Its absence is what the `FLAG_NOT_FOUND` scenario tests. Seeding
  it turns that scenario green for the wrong reason.
- **Only `targeting-key-flag` has a targeting rule.** Every other enabled flag resolves to its
  default variant whatever the evaluation context, which is what lets a provider declaring
  `@standard-reasons` expect `STATIC` rather than `TARGETING_MATCH` for them. Seeding targeting onto
  any other flag breaks them in every language at once.
- **The four `disabled-*` flags are the only ones whose state is not `ENABLED`.** They resolve to
  nothing: the caller's default stands in. Every other scenario assumes a flag serves its own
  value, so enabling one of these, or disabling anything else, breaks that assumption silently.

### The control API

Scenarios need to change flags and simulate outages, and they need to do it identically across
vendors. The control API is a small HTTP surface the backend under test exposes for that purpose:

| Endpoint | Required | Purpose |
| --- | --- | --- |
| `POST /start?config=<name>` | yes | start the backend, seeding flags to a named baseline |
| `POST /stop` | yes | make the backend unreachable |
| `POST /restart?seconds=<n>` | no | simulate a *bounded* outage, preserving flag state |
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
- **An endpoint that changes flag state must not return success until that state is being served.**
  Returning when the change has been *accepted* rather than *applied* pushes a race onto every
  caller, and the caller cannot close it: a suite has no way to distinguish "the backend has not
  caught up yet" from "the provider resolved the wrong value", which is the exact question it
  exists to answer. Readiness of the process is not readiness of the state — a backend whose health
  probe reports ready as soon as a configuration has been *handed over* to be parsed will answer
  `FLAG_NOT_FOUND` for flags the configuration plainly defines, and a provider that happens to
  block during its own initialisation absorbs the window while a stateless one races it. The result
  is a suite that flaps per provider rather than per backend, which is the most misleading shape a
  conformance failure can take.

  A suite must not paper over a backend that breaks this, and **that includes an adoption**. A delay
  buys silence, not correctness: it hides the defect from the one consumer positioned to notice, and
  it is un-tunable, because the window it covers is a property of the backend and not of the suite.

  An earlier revision of this appendix said the wait belonged in the adoption, named and citing the
  defect. That was wrong. One backend's defect becomes every adoption's problem, solved once per
  language; and an adoption that compensates cannot be compared with one that does not, against the
  same backend — so the suite risks reporting a difference in harness behaviour as though it were a
  difference in provider behaviour, which is the one thing a conformance suite must never do.

  The one such workaround written under the old guidance turned out to buy nothing: removing it left
  its suite on the same tally, four runs running, and faster for no longer polling. That is the
  clearest argument against the shape. A compensating wait is hard to show is load-bearing, easy to
  leave in place long after the defect it named is fixed, and certain to make two adoptions'
  results incommensurable in the meantime.

  **So the wait belongs in the backend.** A backend that returns before it serves has a defect to be
  filed and fixed where the backend lives. Until it is, the suite fails, the failures are read
  against a documented floor, and a run is repeated before an extra failure is attributed to the
  provider — a race hits a different scenario each time, a defect hits the same one.

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
| `@disabled-flags` | resolves a flag disabled in the management system to the code default |
| `@unavailable` | reports an error state instead of hanging against a dead backend |
| `@numeric-coercion` | coerces between integer and float only when lossless, else `TYPE_MISMATCH` |
| `@string-typing` | reports `TYPE_MISMATCH` for a boolean or integer flag requested as a string, rather than its string representation |
| `@fully-typed-values` | records a native type for float and structured values too, so the same question can be asked of them |
| `@large-integers` | resolves integers up to 2^53 − 1 exactly; undeclarable where the SDK's integer accessor is 32-bit |
| `@reinitialization` | can be initialised again after `shutdown`, which [Requirement 2.5.2](./sections/02-providers.md#requirement-252) permits rather than requires |
| `@targeting` | resolves a flag differently for a matching evaluation context |
| `@standard-reasons` | reports the standard resolution reasons, with the meanings given below |
| `@caching` | reserved; **not declarable** -- no scenarios yet |

Untagged scenarios are mandatory and always run.

A reserved tag is documented so the vocabulary has a place for the capability when scenarios exist,
but it must not be declared.

> A reserved capability **MUST NOT** be declared, and **MUST NOT** appear in a conformance report's
> declaration. A TCK implementation **MUST** refuse one an adopter names.

No
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

`@stale` is gated for the same reason, and it is worth stating because the tag's name reads like an
obligation. [Requirement 5.1.1](./sections/05-events.md#requirement-511) offers two responses to a
provider losing its backend, in consecutive sentences and with the same modal: one unable to evaluate
flags *"can signal this by emitting a `PROVIDER_ERROR` event"*, and one that caches rule-sets or
previously evaluated flags *"can signal this by emitting a `PROVIDER_STALE` event"*. **Can, twice.**
A provider that goes straight to `ERROR` on connection loss is exercising the first option, not
failing the second — and it is the safer of the two, since it is not quietly serving cached values
while disconnected.

So an absent `@stale` is a design choice and **must not be recorded as a known deviation**. The flagd
provider is the worked example and it differs by transport: its in-process resolver emits
`PROVIDER_STALE` on connection loss and escalates to `PROVIDER_ERROR` when a retry grace period
expires, while at least one language's RPC resolver emits `PROVIDER_ERROR` directly and never
`PROVIDER_STALE`. Both are conformant. That two transports of one provider answer differently is
worth knowing — an application switching resolver stops receiving stale events — but it is a
portability finding, not a conformance failure, and the report should carry it as an undeclared
capability rather than a defect.

The design rule behind this: **a conformance suite that quietly goes green on scenarios it did not
run is worse than no suite at all** — and, learned later and at some cost, one that reports a
permitted choice as a failure is not much better. A TCK implementation must report unsupported
capabilities as skipped and surface the reason, not silently pass or silently omit them; and a
scenario must be gated whenever the behaviour it asserts is one the specification allows a provider
to decline.

### Rules for declaring

The six rules below are stated rather than implied because each was discovered by four
implementations answering the same question differently. They are what makes two reports comparable.

**Once a provider is attempting a capability, declare it when at least one scenario gating it can
actually be put to the provider, and withhold only when none can.** The unit of this decision is the
*scenario*, not the tag — which is the part that is easy to miss, and the part three implementations
got wrong in three different directions.

The opening clause is a real condition and not throat-clearing. This rule decides *whether the
question is askable*; it does not decide whether the provider owes an answer, and that question comes
first. Where the specification permits declining — `@numeric-coercion` is not defined by any
requirement, so a provider may simply not coerce — withholding is the honest report however askable
the scenarios are. Applying this rule to that case turns a permitted choice into a manufactured
failure, which is the mirror image of the mistake it exists to prevent.

The case that forces it is a backend that does not serve a flag some scenario needs. `@large-integers`
has exactly one scenario, and it asks for a flag the reference backend does not serve, so nothing
about that capability can be established and withholding is right. `@numeric-coercion` has three, and
a backend missing one flag can still be asked the other two — so withholding it hides two answers to
save one failure. That is not hypothetical: declaring it is how one provider's two resolvers were
found to *disagree with each other*, one coercing correctly and one not, which no amount of reading
the source had revealed.

Two consequences worth stating. A scenario that fails because the backend cannot serve its fixture is
**not** a provider defect and must not be recorded as one — say so in the deviation's summary, or the
report accuses the provider of the backend's gap. And a capability withheld for a backend gap is
**temporary** in a way one withheld by choice is not: it should be revisited when the backend gains
the fixture, so note why, or it will outlive its reason.

**A capability the language's SDK cannot express is refused by the implementation, not left to
adopters.** Two exist today: `@large-integers` where the integer accessor is 32-bit, and
`@numeric-coercion` where the language has a single numeric type. Neither says anything about a
provider -- no provider in that language can satisfy them, and none ever will until the SDK changes.

Leaving it to adopters means every adopter in that language has to know a fact about their language
and remember to act on it. That is not hypothetical: in one implementation three separate suites
each left the same capability undeclared, each with its own comment explaining the same property of
the language. Three places to get it right, and a single wrong one puts a claim in a report that no
scenario could have verified -- the exact failure the reserved-capability rules prevent, reached by
another route.

> A TCK implementation **MUST** refuse a capability its language's SDK cannot express, rather than
> leaving each adopter to withhold it.

So the implementation refuses it at configuration time, as it refuses a reserved capability. **The
two refusals are not the same thing and their skip reasons must differ.** A reserved capability is
global and temporary: no scenario anywhere carries the tag, and the reservation expires the moment
the specification adds one. An inexpressible capability is one language's and permanent: the
scenarios exist and pass elsewhere. A reader who sees a capability absent from a report needs to know
which of *"this provider declined"* and *"no provider in this language can be asked"* they are
looking at, because only the first says anything about the provider.

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

**A deviation is legitimate in two shapes, and the results already tell them apart.** Which one an
adopter reaches for is the single most consequential thing about this field, so it is stated here
rather than left to each implementation's documentation — four implementations left to themselves
produced three different answers, and a consumer comparing their reports would read one field three
ways.

1. **The capability is declared, the scenario runs, and it fails.** The failure stays in the
   results and the deviation says it is known, what it is, and where it is tracked.
2. **The capability is withheld, and the scenarios it gates are skipped.** The deviation explains
   the absence, so that a reader can tell a defect from a design decision. Both look identical
   otherwise: scenarios skipped, reason recoverable from the declaration.

**Prefer the first.** The second is honest only when the provider cannot attempt the behaviour at
all, so that running the scenario would establish nothing. Where the provider does attempt it and
gets it wrong, withdrawing the capability replaces a failing scenario with a skip and hides a defect
behind something that looks deliberate — which is the outcome this field exists to prevent, not one
of its uses. A conformance report is not improved by having fewer failures in it.

**A TCK implementation's own self-tests are the one place where withholding to stay green is
acceptable**, and it is worth saying so because the rule above otherwise forbids it. Those suites run
the conformance scenarios against an SDK's in-memory provider as a fixture for the harness; they are
not an adoption and they produce no report about a third party. They also run in the implementation's
ordinary build, where a permanently failing scenario is a broken build rather than a finding — and
nobody downstream can act on it, because the defect belongs to the SDK and the fix is a release away.

So a self-test may leave a capability undeclared for a defect it has identified, on one condition:
**the defect is pinned by a test of its own**, so that the behaviour is still asserted and the skip
is not the only record. Go's in-memory self-test does this for `@disabled-flags` against a
`memprovider` defect fixed upstream but unreleased. An adoption has no such licence: it exists to
report on a provider, and a skip there is a claim about that provider.

**`summary` is required; `issue` is not.** A deviation whose summary is empty records that something
is wrong without saying what, which leaves a reader worse off than the bare skip or failure it
accompanies. An untracked deviation is worth declaring even so: naming the defect is what separates
it from a withheld capability, and a declaration that merely omits the tag cannot say which of the
two happened. Prefer a tracked one as soon as there is somewhere to point at.

**Emit `knownDeviations` only when there is at least one.** An empty array and an absent field are
not the same claim: stating none asserts that deviations were considered and none found, which no
suite can know on the adopter's behalf. Omit the field when the list is empty, and never synthesise
an empty one.

### `@standard-reasons`: a claim, not an exemption

[Requirement 2.2.5](./sections/02-providers.md#requirement-225) is a `SHOULD` that lets a provider
populate `reason` with a listed value *"or some other string indicating the semantic reason"*. A
provider reporting vendor-specific reasons is therefore conformant, and asserting an exact reason
against it would fail it for something the specification permits. So the reasons live in
`reason.feature`, gated as a whole, rather than asserted throughout. (An earlier revision asserted
them in thirteen places and recorded the narrowing as a deliberate exception; it bought little, since
every canonical flag resolves to a value distinct from the caller's default and the value assertion
already catches a silent fallback.)

**Declaring `@standard-reasons` says "I use the standard vocabulary with the standard meanings", and
`reason.feature` checks the claim.** A provider that does not declare it loses nothing — its values,
variants and error codes are asserted elsewhere, on `MUST` requirements. What the declaration adds is
something a report's reader can act on: anyone building telemetry or debugging on `reason` can see the
vocabulary was verified rather than assumed. The meanings below are the content of an opt-in claim and
constrain nobody who does not make it.

| Situation | Reason |
| --- | --- |
| The flag was resolved from configuration and carries no targeting rule | `STATIC` |
| A targeting rule matched the evaluation context | `TARGETING_MATCH` |
| A targeting rule exists and did not match | `DEFAULT` |
| The flag is disabled in the management system | `DISABLED` |
| The evaluation failed, and an error code is reported with it | `ERROR` |

`STATIC` for the first row is the call worth flagging: `types.md` types `DEFAULT` as *"no dynamic
evaluation occurred **or** dynamic evaluation yielded no result"*, which a rule-less flag satisfies as
readily. Two providers can disagree here and both conform. One answering `DEFAULT` is not defective —
it does not use the standard meanings, and should not declare the tag.

**`ERROR` asserts agreement, not authorship.** The other four rows rest on
[1.4.7](./sections/01-flag-evaluation.md#requirement-147), which makes the SDK propagate the
provider's reason — but only *"in cases of normal execution"*. Abnormal execution is
[1.4.9](./sections/01-flag-evaluation.md#requirement-149), a `SHOULD` on the **SDK**, and nothing
requires the provider's reason to survive. So a passing `ERROR` scenario establishes that the value
reaching the application is coherent, not that the provider produced it — which is still worth
asserting, because the pair carries the meaning. The error code alone is already a `MUST` for every
provider and asserted ungated; the reason alone could have been written by the SDK. `FLAG_NOT_FOUND`
with reason `STATIC` is incoherent whoever wrote it, and the pairing is what catches it.

`SPLIT`, `UNKNOWN`, `CACHED` and `STALE` are not asserted: the first two have no scenario producing
them, and the last two need a repeat evaluation and an assertion about what a provider serves *during*
an outage — both under known gaps.

**That "repeat evaluation" exclusion is load-bearing.** It is what keeps these assertions correct
against a provider that caches, and it means the configuration-change scenarios silently depend on
cache invalidation working: if it did not, the evaluation after the change would answer from the cache
and fail somewhere that says nothing about configuration change. Nothing tests invalidation directly,
so an adoption against a caching provider rests on it untested. Adoptions need not disable a
client-side cache — a provider measured as it ships is more useful — but an implementer should know
the dependency is there before reading such a failure.

**Tags compose, and here that is load-bearing.** `TARGETING_MATCH` cannot be observed without
targeting and `DISABLED` cannot be observed unless the backend distinguishes a disabled flag, so those
scenarios also carry `@targeting` and `@disabled-flags`. A provider declaring `@standard-reasons`
alone runs the rest and skips those two with their reason.

`@variants` is the same shape, found the hard way: every evaluation scenario once asserted a variant,
which reads as obviously correct until a backend with no variant concept is put under test — its
response carries no such key, no seeding can produce one, and ten scenarios failed a conformant
provider for something its author could not fix.
[2.2.4](./sections/02-providers.md#requirement-224) is a `SHOULD` and `types.md` types the field
optional; the suite was asserting a `MUST` neither states.

### `@numeric-coercion`: a borrowed rule, not a specified one

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
[open-feature/flagd#1996](https://github.com/open-feature/flagd/issues/1996). **A provider in that
position should declare the capability and let the scenario fail**, with a `knownDeviations` entry
beside it: it does coerce, and gets one direction wrong, which is precisely what a skip cannot
express. An earlier revision of this paragraph said such a provider should withhold the capability
and explain which it was, and that contradicted the known-deviation rule a few sections above — the
one place a reader would look to learn the shape. Two of the four implementations followed it into
exactly the combination that rule exists to discourage, so the wording is corrected here rather than
worked around there.

Withholding remains right for a provider that **cannot attempt** the behaviour — one whose SDK has a
single numeric type, where the distinction does not exist to get wrong.

Both halves of the rule have scenarios. The lossy half asks for `float-flag` (`0.5`) as an integer
and expects `TYPE_MISMATCH`; the lossless half asks for `integral-float-flag` (`10.0`) as an integer
and for `integer-flag` (`10`) as a float, and expects both to succeed. A provider declaring the tag
must satisfy all three — rejecting every float is an easy way to pass the first, and the other two
are what stop it. A provider whose SDK has a single numeric type, such as JavaScript, cannot
distinguish the cases at all, so it leaves the tag undeclared and the scenarios are reported as
skipped with that reason.

### `@string-typing`: the same gap, one type further out

`@string-typing` is the same question reached from the other direction, and it needs stating
separately because it breaks the reasoning that had kept four scenarios mandatory.

Every value has a string representation. A backend that stores flag values as strings — Flipt does,
and so do some Flagsmith configurations — therefore satisfies the string accessor for **every** flag
and has no mismatch to report. Its flags are strings;
[Requirement 2.2.3](./sections/02-providers.md#requirement-223) asks it to populate `value` with the
resolved flag value, and it did.

Nothing in the specification contradicts that, because the specification never says what the type of
a flag value **is**. `TYPE_MISMATCH` appears exactly once, as a row in the
[error code table](./types.md), and no requirement obliges anyone to raise it. The only normative
statement about value type is [Requirement 1.3.4](./sections/01-flag-evaluation.md#requirement-134) —
a `SHOULD`, and on the **client** rather than the provider. The provider requirements do not mention
type at all.

So this tag sits upstream of [open-feature/spec#430](https://github.com/open-feature/spec/issues/430), and is tracked as [open-feature/spec#433](https://github.com/open-feature/spec/issues/433):
that issue asks which accessor a number may satisfy, this one asks what a flag's type is when the
backend has none. Until the specification answers it the rule is borrowed, exactly as the numeric one
is, and **a provider that withholds the tag is not violating the specification**.

Four scenarios moved out of the mandatory matrix to make that honest: `boolean-flag`, `integer-flag`
and `float-flag` requested as strings, and `object-flag` requested as a string — the last tagged
`@object` too, since a provider with no structured values cannot be asked at all. The matrix had
justified keeping them on the grounds that *"is a string a boolean?"* has no defensible wrong answer.
That holds for parsing a string into another type, which a provider chooses to do; it does not hold
for rendering another type as a string, which an untyped backend does whether anyone chose it or not.
The asymmetry was real and pointed the wrong way. The case came from a Flipt provider written against
this suite, where those rows failed for a provider behaving reasonably.

Withholding rather than a deviation is the right instrument, for the reason given under
[Rules for declaring](#rules-for-declaring): a deviation records a required behaviour the provider
lacks, and this behaviour is not required.

#### Why this is two capabilities

The first draft of this made it one tag over all four cases, and measurement showed that a single
tag **hides defects inside a permitted absence**. Three providers were run against one Flagsmith
backend:

| requested as a string | Go | Java | JavaScript |
| --- | --- | --- | --- |
| `boolean-flag` | `TYPE_MISMATCH` | `TYPE_MISMATCH` | `"true"` |
| `integer-flag` | `TYPE_MISMATCH` | `TYPE_MISMATCH` | `"10"` |
| `float-flag` | stringified | stringified | stringified |
| `object-flag` | stringified | stringified | stringified |

The bottom two rows are the backend: Flagsmith records no native float or structure type, so no
provider over it can report a mismatch, and the absence is permitted. The top two are not — that
store does record booleans and integers, two providers answer them, and the third fails them
because of its own code rather than the backend's shape. Under one tag that provider withholds and
its defect is reported as a permitted absence, which is the worst of the available outcomes: the
suite goes quiet on a real bug. Two tags separate the question the backend cannot answer from the
question a provider got wrong.

The general rule this is an instance of: **a capability coarser than the variation providers
actually show will hide defects inside permitted absences.** When one tag would gate scenarios
that fail for different reasons, it is the wrong unit of declaration.

### Capabilities a language cannot express

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

A TCK implementation is the language-specific harness around these three artifacts. Each obligation
below is stated first and explained after; the explanations are why, not what.

### Ship the artifacts

> A TCK implementation **MUST** package the Gherkin scenarios, the canonical flag set and the control
> API document with the library, so that an adopting provider needs no submodule of its own.

> A TCK implementation **MUST** make it impossible to run the suite against assets the build did not
> fetch.

Three of four implementations could run against stale assets, by three different routes, and one did:
a full adoption suite ran against the *previous* pin's feature files and reported a tally
byte-identical to the run before it — nothing failed, nothing warned, and it was caught only by
someone comparing two numbers that should have differed. The cause is the same wherever a copy is
involved: moving a pin updates the recorded revision, not the working tree the build copies from, so
the two disagree silently and the copy wins.

Wire the fetch into the build rather than relying on whoever moves the pin to remember a second
command. Where the assets arrive as an immutable, checksummed dependency the problem does not arise,
and that is worth preferring. A guard that catches one symptom — a declared capability no scenario
carries, say — is worth having and is not a substitute: a pin that changes only the *content* of a
scenario passes every such guard and still tests the wrong thing.

### Implement the step definitions

> A TCK implementation **MUST** implement the step definitions against its language's OpenFeature
> SDK, using that language's Cucumber or equivalent runner.

### Own the lifecycle

> A TCK implementation **MUST** own the suite lifecycle — starting the backend stack, registering the
> provider under test, awaiting events and tearing down — so that an adopting provider writes no test
> infrastructure.

If a provider author finds themselves adding lifecycle code, that is a defect in the TCK.

> A TCK implementation **MUST** own the container stack: given a Compose file, a service name and the
> container-internal ports the provider connects to, it starts the stack, discovers the dynamically
> mapped host ports, builds the control client, waits until the control API accepts commands, and
> tears down after the last scenario.

This is the part implementations get wrong. Shipping only the control-API client and leaving
orchestration to the adopter satisfies the letter of the previous requirement and not its point: the
orchestration is then rewritten by every adopting provider, and it is the largest single piece of test
infrastructure in an adoption.

> A TCK implementation **MUST** start the backend stack once per suite and **MUST NOT** restart it.

Container runtimes assign host ports dynamically and do not reliably preserve them across a restart,
so a restart silently invalidates every provider already pointed at the old port. Backend
unavailability is simulated inside the running stack through the control API, which is what `@stale`
and `@unavailable` already require.

> A TCK implementation **MUST** wait for the stack by asking the control API whether it is ready,
> bounded by the startup timeout, and **MUST NOT** wait after any control call.

> A TCK implementation **MUST NOT** add a delay to compensate for a backend that
> returns before it serves, and an adoption **MUST NOT** either.

A control endpoint that changes flag state owes the caller that the state is being served before it
returns — see the control API's invariants. A backend that breaks that has a defect to fix in the
backend, and compensating for it anywhere in the suite makes that adoption's results incomparable
with every other adoption run against the same backend.

### Drive the backend only through the control API

> A TCK implementation **MUST** drive the backend only through the control API.

This is what makes the conformance claim portable: another language's TCK drives the same endpoints
against the same stack and must get the same answers.

### Gate on capabilities

> A TCK implementation **MUST** report a scenario gated on an undeclared capability as skipped with
> its reason, and **MUST NOT** report it as passed.

### Run scenarios serially

> A TCK implementation **MUST** run scenarios serially.

Backend state is global to the suite; concurrent scenarios corrupt each other, and the symptom looks
like a flaky provider rather than a broken test.

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

**Which of the two paths a run used is stated by the control, not inferred by the harness, and it is
not optional.** It is the one fact that decides what everything else in a result is worth: the same
scenarios passing over the normative control API and passing through in-process manipulation of a
provider that has a real backend are not the same claim. Nothing outside the control can tell the
two apart — a harness that infers it from the control's concrete type is right about its own two
built-in controls and silently wrong about an adopter's custom one, which is the case where the
answer actually matters. Nor is an absent value neutral: every run is one or the other, so an
omitted value is not "no claim made", it is an unfalsifiable one. A control that cannot say which
path it used is not finished.

### Running the suite in CI

Guidance rather than a rule — a pipeline is a repository's own business — but leaving it unwritten
produced four different mechanisms and one unnoticed consequence.

**An adoption suite is not a required gate while real gaps remain.** Its honest output is red — filed
provider defects, missing backend fixtures, unimplemented capabilities — and a red result is the suite
working. Making it block a merge forces someone to silence it, and the cheapest way to silence a
conformance suite is to stop asking the question.

So **exclude it from the default build, and make the exclusion explicit.** Two mistakes to avoid,
both observed:

- **An exclusion something else undoes.** The question is not whether one exists but whether any
  profile, target or job re-enables it. All four languages believed their suites were excluded; all
  four were running them, red and unwatched, by four different routes.
- **An exclusion nobody wrote down**, which is indistinguishable from an oversight. State it where an
  adopter will read it.

Provide a single documented command that runs the suite deliberately, and **keep the adoption
typechecked by something that runs ordinarily**, even though it does not execute — a conformance
suite that has quietly stopped building against its own harness is a worse failure than one that
runs and fails.

"Something that runs ordinarily" rather than "the default build", because where that build compiles
what gets *published* it is configured for library code — no test globals, a different module target —
and an adoption calling the test framework's own functions can never join it. A typecheck scoped to
the adoption meets the requirement instead, which is a further argument for the suite having a
directory of its own: a directory nothing else occupies is something a typecheck can be pointed at.

Two opposite failures, both observed: excluding by path can remove the adoption from the build as well
as the run, silently, because nothing fails when nothing compiles; removing an exclusion can pull it
*into* a build that cannot compile it, which at least fails loudly. Assert it rather than assume it —
introduce a deliberate compile error and confirm the ordinary build rejects it.

**Give it a step of its own, rather than folding it into an existing end-to-end suite.** This holds
whatever is decided about gating, and the reason is what a result *means* rather than how long it
takes. A dedicated step reports on **conformance**; the same scenarios inside a provider's own e2e
suite report that a test passed or failed, and a reader has to go and find out which kind.

Note that this is about a build target, not a CI job, and the two are easy to conflate — a suite can
have a step of its own that no pipeline invokes, which is the position every implementation is in
while the gating question below is open. The step still earns its place: a maintainer running it by
hand gets an unambiguous answer rather than a mixed one, and if gating is resolved in favour of
running it, the thing to gate on already exists and is already scoped correctly.

**Keep the conformance suite separable from the provider's other suites, and do not select it by
naming convention.** The unit does not matter — a directory, a module, a project, whatever the
language's tooling selects on — but it should be possible to run the conformance suite, and only it,
without enumerating or pattern-matching individual test names.

Naming conventions work until a test is renamed, and then they fail in the direction that hides the
problem: the suite stops being selected, the step goes green having run nothing, and the tally in a
pull request keeps quoting numbers from the last time it did run. Every language that selected by
name had to build something to defend the convention — an AST parser asserting that the set of tests
calling the runner equals the set matching the name pattern, mutation-tested in both directions. The
languages that selected by directory needed nothing, because a file is in it or it is not.

Filing the conformance suite *inside* the provider's end-to-end directory is the same mistake one
level down. It says the suite is a kind of end-to-end test, which is what a step of its own exists to
deny — and where the end-to-end suite is its own module, it also drags the conformance suite's
dependencies, container libraries and all, into tests that never use them.
The two also differ in what a failure means: an e2e suite is expected green, so a failure is a
regression, while a conformance suite carries failures by design — a declared `knownDeviation` fails
its scenario deliberately, and that failure is correct output until the defect is fixed upstream.
Sharing one signal between "you broke something" and "this is the known state" reliably ends with
somebody silencing the informative half.

> **The gating half of this section is provisional.** It rests on the premise that a conformance
> run's output is unavoidably red, and therefore cannot be a required gate. That premise is under
> discussion in [open-feature/spec#417](https://github.com/open-feature/spec/issues/417): if a run is
> judged by whether its **results match its declaration** — every failure covered by a declared
> deviation, every skip gated by an undeclared capability, and every declared deviation still
> failing something — then a healthy adoption is green in its steady state, deviations included, and
> the suite can be a required gate after all. The separation advice above is unaffected either way.

## The runner

The vocabulary and the artifacts decide what is asked. This section decides whether two languages'
answers mean the same thing. It is here because four implementations agreed on all of it and none of
it was written down — they agreed because one author wrote them in parallel, which is not a mechanism
a fifth implementation can rely on.

### Steps the suite adds

Most of the step vocabulary is inherited (see above). Seven steps are this suite's own, and four of
them assert something other than what their wording first suggests. An implementation that binds them
literally will produce results that are not comparable with anyone else's.

| Step | What it asserts |
| --- | --- |
| `no exception should have been thrown` | That no failure **escaped** the evaluation to the caller — a thrown exception, or a panic in a language without them. Not that the evaluation succeeded: typed evaluation must absorb every error into the returned details, so an error scenario proves both halves, the right error code *and* nothing escaping. The lifecycle scenarios reuse it for a repeated `shutdown()` and for `initialize()` against a reachable backend. |
| `the resolved value is remembered` | Records the current value for a later delta. |
| `the resolved details value should have changed` | That re-evaluation differs from the remembered value — **a delta, not a value**. `POST /change` promises only that `changing-flag` resolves differently; which value it changes to is vendor-defined, so asserting an absolute would bind the scenario to one backend and to how many times it had run. |
| `the connection is lost` / `the connection is restored` | An outage with an explicit start and end. The inherited harness has a self-healing `the connection is lost for {int}s`, which cannot express "assert the provider is stale, *then* reconnect" — the reconnect races the assertion. This is also why no shipped scenario reaches `POST /restart`. |
| `the provider is shut down` / `the provider is initialized again` | Call the provider **directly**, not through the SDK. |
| `the shutdown should have completed within {int}ms` | That shutdown **returned at all** rather than blocking on a backend that will never answer, which would hang the host application's own shutdown. The bound is deliberately generous; it is not a performance assertion. |

### Timeouts

These decide what "promptly" and "timed out" mean, so they decide comparability.

> A TCK implementation **MUST** use these timeout defaults, and **MUST** let an adopter override each
> one.

| | default | bounds |
| --- | --- | --- |
| event | **12 s** | waiting for a lifecycle event a scenario asserts |
| ready | **30 s** | waiting for the provider to reach ready after registration |
| startup | **60 s** | bringing the whole backend stack up, before any scenario runs |

> An explicit `within {int}ms` in a step **MUST** take precedence over the event timeout default.

The step states a bound the scenario is about; the default is only for steps that state none.

### Registering the provider

> A TCK implementation **MUST** register a fresh provider for each scenario, under a domain derived
> from the suite name, and **MUST** replace it at the end of the scenario so the previous provider is
> shut down and its connections released.

Both halves matter. Registering once per suite would change what the lifecycle and reinitialisation
scenarios establish, since they assert against a provider whose state they control. A fresh *domain*
per scenario would leak: registering into a domain replaces and shuts down whatever was there, so a
new domain each time leaves every previous provider registered and running — for a provider holding a
network connection, one leaked connection per scenario.

### Reaching the provider from an extension step

> A TCK implementation **MUST** expose the client and the provider under test to an adopter's
> extension step definitions.

Without it the only way to evaluate a flag from an extension step is to build a second client, which
resolves against a different provider — so the step tests the wiring and reports success having asked
the provider under test nothing.

### Run-integrity checks

Three failures are invisible from the results alone, and two rules below are about the checks
themselves rather than about a provider.

> A TCK implementation **MUST** fail the run when a reserved capability tag is carried by a collected
> scenario.

The tag is reserved because nothing carries it; if something now does, the reservation has expired and
the vocabulary is stale.

> A TCK implementation **MUST** fail the run when a declarable capability gates no collected scenario.

Either the assets are not the ones the implementation thinks it shipped, or a capability has outlived
its scenarios — and in both cases a provider can declare it and be told nothing.

> A TCK implementation **MUST** fail the run when a collected scenario carries a capability tag the
> implementation's vocabulary does not know.

This is the previous check's own direction reversed, and it is the one that is easy to leave out. An
unknown tag gates nothing, so its scenarios stay **mandatory for every adopter** — a suite that has
not learned a new capability does not report a new capability, it silently keeps demanding the old
behaviour. All four reference implementations ignored an unknown tag rather than failing, and the
symptom is a provider that legitimately withholds the capability showing unexplained failures while
every other provider stays green. Nothing in the results says why.

> A TCK implementation **MUST** fail the run when a run-integrity check cannot be performed, rather
> than skipping it.

A check that reports nothing when it cannot do its job is absent exactly where it is needed. The
revision check is the case in point: it compares the assets on disk against the pin, and where the
pin could not be read it skipped — which was also where stale assets were most likely. One adoption
ran a full suite against the previous revision's scenarios and produced entirely plausible numbers,
because the check that would have caught it was skipping and the suite that runs it was not the
suite that ran.

**A check with nothing to check is not the same as a check that cannot be performed**, and this rule
does not reach the first. An unpacked distribution has no pin, no repository, and no working tree
that could have drifted from one: its assets are distribution content, produced by a sync that ran
this check when the distribution was built. Failing there would accuse whoever unpacked it of a
defect they cannot hold or fix. A linked worktree is the opposite case and looks similar only
because git is silent in both — there the pin exists and the implementation was not reading it
correctly, which is a check that must be made to work rather than allowed to skip. An implementation
has to tell the two apart before it applies this rule.

That distinction was argued back from an implementation rather than reasoned out here: an earlier
revision of this section named the two cases in one breath, which would have required failing a
downstream packager. It also produced the better fix for the second case — a worktree records its
git directory as an absolute path, while a submodule's is relative, so the pin is readable from the
submodule side and the condition disappears instead of being reported.

That last point generalises past the check itself:

> The revision check **MUST** be in force where the scenarios execute, not only in the TCK
> implementation's own tests.

An adopter runs the canonical scenarios from its own build. A guarantee that holds only in the
implementation's test suite does not cover the run whose results are being published.

## Extending the suite

A provider often has behaviour this specification does not describe — flagd's fractional targeting,
a vendor's own segment rules — and no way to test it inside this suite. The alternative an adopter
reaches for is a parallel harness that reimplements provider registration, the readiness wait and
the per-scenario backend reset, and then drifts from the one here.

> A TCK implementation **MUST** offer an extension point, through which an adopter supplies feature
> files and step definitions that run inside the same suite, against the same backend, and in the
> same lifecycle phase — one backend start and teardown covering canonical and extension scenarios
> alike.

This is a requirement rather than a suggestion, and the reason is what happens when it is not. In a
runner that resolves steps dynamically the extension point is nearly free; in one driven by
declarative suite annotations it is not, and an implementation that skipped it would leave adopters
unable to add a feature file without redeclaring the whole set. Those adopters do not then go
without — they build the parallel harness, which is the outcome this section exists to prevent, and
by the time it exists the cost of retrofitting the extension point is paid by someone else. Requiring
it makes the cheap thing happen while it is still cheap.

The mechanism is the implementation's own — a classpath scan, a `conftest.py`, two configuration
fields — and this appendix does not prescribe one. What it does prescribe is the four properties that
keep an extension from quietly becoming a conformance claim.

> Extension scenarios **MUST** be distinguishable from canonical ones in the results.

A payload that mixes them with no way to tell which is which lets an adopter's own passing scenarios
flatter the conformance result. Partitioning by path is enough, and it is what a consumer reads to
separate the two:

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

The first implementation is `tools/tck` in
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
- **`@stale` is exercised only against a real backend.** Every other capability has at least one
  implementation covering it without containers — an in-memory or controllable provider standing in
  for the backend — so a regression in the step definitions or the gate is caught in an ordinary
  build. `@stale` is not covered that way anywhere, in any of the four implementations, because
  simulating a provider that loses its backend and regains it needs a control that can disconnect,
  and the in-process control paths deliberately refuse connection operations. So the stale/ready
  transition is only ever exercised by a containerised adoption, which is also the suite most likely
  to be excluded from a default build. A controllable provider able to fake a disconnect would close
  it, and would need care not to become a mock that passes whatever the provider does.

- **Caching.** Whether a stale provider keeps serving last-known values during an outage depends on
  whether it holds a local copy of the ruleset. The `@caching` tag is reserved; no scenarios yet.

  Worth knowing before writing them: a provider may cache on the client side and *rewrite the
  reason* when it does. flagd's RPC resolver runs an LRU cache by default and reports `CACHED` on a
  repeat evaluation of an unchanged flag. So any scenario that evaluates the same flag twice in one
  scenario — the obvious shape for a caching test, and equally for a "value is stable" test — will
  see a different reason the second time from a provider that is behaving correctly. This is why no
  existing scenario evaluates a flag twice without a configuration change in between, and it is a
  constraint on new scenarios rather than a defect in any provider.
- **Coverage of the numbered requirements.** Mapped against
  [the provider requirements](./sections/02-providers.md), leaving out 2.8.5.1 (it constrains the SDK)
  and 2.2.8.1 (a language-binding property, not observable at runtime), the suite covers 10 of the
  14 `MUST` requirements in scope, all 5 `SHOULD` — 2.2.4 only for a provider declaring `@variants`,
  and 2.2.5 only for one declaring `@standard-reasons` — and 1 of 6 `MAY`. The `MUST` gaps are
  2.3.1 (the provider hook mechanism, a compile-time
  property in typed languages with little to observe at runtime), 2.2.10 (flag metadata structure,
  blocked with 2.2.9 on the canonical flag set defining
  none), 2.4.4 (a domain-scoped provider accepts its bound domain, which is as much SDK as provider
  behaviour) and 2.8.4 (`PROVIDER_CONTEXT_CHANGED`). The last is the largest hole: context
  reconciliation is where a provider is most likely to serve values computed for the *previous*
  context, and the failure is silent. It wants its own capability tag, and until the control API has
  an echo operation a scenario can show only that reconciliation was signalled, not that the values
  that follow are the new context's.
- **Normative status.** The obligations on a TCK implementation are stated as normative blockquotes,
  in the style Appendix A uses, and deliberately carry no numbers: `specification.json` builds its
  rules from the numbered sections only, so numbers here would be inert, and this appendix *tests*
  numbered requirements — a second scheme beside them would put provider obligations and harness
  obligations in one namespace. Whether the control API contract and the capability vocabulary should
  instead be promoted to a numbered section remains a decision for the TSC.
