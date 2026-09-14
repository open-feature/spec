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
| `@large-integers` | resolves integers up to 2^53 − 1 exactly; undeclarable where the SDK's integer accessor is 32-bit |
| `@reinitialization` | can be initialised again after `shutdown`, which [Requirement 2.5.2](./sections/02-providers.md#requirement-252) permits rather than requires |
| `@targeting` | resolves a flag differently for a matching evaluation context |
| `@standard-reasons` | reports the standard resolution reasons, with the meanings given below |
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

### `@standard-reasons`: a claim, not an exemption

[Requirement 2.2.5](./sections/02-providers.md#requirement-225) is a `SHOULD`, and it goes further
than 2.2.4 does: it lets a provider populate `reason` with one of the listed values *"or some other
string indicating the semantic reason for the returned flag value"*. A provider whose backend
reports vendor-specific reasons is therefore conformant, and asserting an exact reason against it
would fail it for something the specification permits.

An earlier revision of this suite did exactly that, in thirteen places across three feature files,
and recorded the narrowing here as a deliberate exception. It is not one any more, for two reasons.
It bought very little: every canonical flag resolves to a value distinct from the caller's default,
so a provider that silently falls back is already caught by the value assertion, and the reason only
said *why* it failed. And of the thirteen, five sat beside an error-code assertion that already
carries the `MUST`, while the other eight asserted `STATIC` -- the one reason the specification
genuinely leaves open.

So the reasons now live in `reason.feature`, gated as a whole. **Declaring `@standard-reasons` is a
provider saying "I use the standard vocabulary with the standard meanings", and that file is what
checks the claim.** A provider that does not declare it loses nothing: its values, variants and error
codes are asserted everywhere else, on `MUST` requirements. What the declaration adds is something a
report's reader can act on -- anyone building telemetry, dashboards or debugging on `reason` can see
that the vocabulary was verified rather than assumed.

This also settles a question the specification does not, without asking it to. The meanings below are
the content of an opt-in claim; they constrain nobody who does not make it.

| Situation | Reason |
| --- | --- |
| The flag was resolved from configuration and carries no targeting rule | `STATIC` |
| A targeting rule matched the evaluation context | `TARGETING_MATCH` |
| A targeting rule exists and did not match | `DEFAULT` |
| The flag is disabled in the management system | `DISABLED` |
| The evaluation failed, and an error code is reported with it | `ERROR` |

`STATIC` for the first row is the call worth flagging. `types.md` types `DEFAULT` as *"no dynamic
evaluation occurred **or** dynamic evaluation yielded no result"*, which a rule-less flag satisfies
as readily as `STATIC` does -- two providers can disagree here and both conform. A provider that
answers `DEFAULT` for a rule-less flag is not defective; it does not use the standard meanings, and
should not declare the tag.

`ERROR` is the row where this suite's subject is blurred, and it is asserted anyway. The other four
rest on [Requirement 1.4.7](./sections/01-flag-evaluation.md#requirement-147), which makes the SDK
propagate the provider's reason — but only *"in cases of normal execution"*. Abnormal execution is
[1.4.9](./sections/01-flag-evaluation.md#requirement-149), a `SHOULD` on the **SDK** to "indicate an
error", and nothing requires the provider's reason to survive. So a passing `ERROR` scenario
establishes that the value reaching the application is coherent, not that the provider produced it.

That is still worth asserting, because it is the pair that carries the meaning. The error code alone
is already covered for every provider — 2.2.7 and
[1.4.8](./sections/01-flag-evaluation.md#requirement-148) make it a `MUST`, it is a closed
enumeration, and `errors.feature` asserts it ungated. The reason alone could have been written by the
SDK. An evaluation reporting `FLAG_NOT_FOUND` with reason `STATIC` is incoherent whoever wrote it,
and that is what the pairing catches.

`SPLIT`, `UNKNOWN`, `CACHED` and `STALE` are not asserted. The first two have no scenario that
produces them. `CACHED` needs a repeat evaluation, which nothing here performs without a
configuration change in between -- see the caching entry under known gaps. `STALE` needs a scenario
asserting what a provider serves *during* an outage, which is the same gap.

**The "without a configuration change in between" is doing more work than it looks.** It is what
keeps the reason assertions correct against a provider that caches, and it means the
configuration-change scenarios silently depend on that provider's cache invalidation working: if it
did not, the evaluation after the change would answer from the cache and the scenario would fail
somewhere that says nothing about configuration change. No scenario tests invalidation directly, so
an adoption against a caching provider is resting on it untested. Adoptions are not required to
disable a client-side cache -- a provider evaluated as it ships is the more useful measurement --
but an implementer should know the dependency is there before reading such a failure.

**Tags compose, and here that is load-bearing.** `TARGETING_MATCH` cannot be observed without
targeting, and `DISABLED` cannot be observed unless the backend distinguishes a disabled flag, so
those scenarios carry `@targeting` and `@disabled-flags` as well. A provider declaring
`@standard-reasons` alone runs the rest and skips those two with their reason.

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

   **The container stack is part of that, and it is the part implementations get wrong.** An
   adopter names a Docker Compose file, says which service and which container-internal ports the
   provider connects to, and supplies a factory that builds a provider from a discovered endpoint.
   Everything else — starting the stack, discovering the dynamically mapped host ports, building
   the control client, waiting until the control API accepts commands, tearing down after the last
   scenario — belongs to the TCK. Shipping only the control-API client and leaving orchestration to
   the adopter satisfies the letter of this item and not its point: the orchestration is then
   rewritten by every adopting provider, and it is the largest single piece of test infrastructure
   in an adoption.

   Start the stack **once** per suite and never restart it. Container runtimes assign host ports
   dynamically and do not reliably preserve them across a restart, so a restart silently
   invalidates every provider already pointed at the old port. Backend unavailability is simulated
   inside the running stack through the control API, which is what `@stale` and `@unavailable`
   already require.

   **Make it impossible to run the suite against assets you did not just fetch.** Three of four
   implementations could, by three different routes, and one of them did: a full adoption suite ran
   against the *previous* pin's feature files and reported a tally byte-identical to the run before
   it — nothing failed, nothing warned, and it was caught only by someone comparing two numbers that
   should have differed. The cause is the same everywhere a copy is involved: moving a pin updates
   the recorded revision, not the working tree the build copies from, so the two disagree silently
   and the copy wins.

   Wire the fetch into the build so the suite cannot run without it, rather than relying on whoever
   moves the pin to remember a second command. Where the assets arrive as an immutable, checksummed
   dependency the problem does not arise at all, and that is worth preferring. A guard that catches
   one symptom — a declared capability no scenario carries, say — is worth having and is not a
   substitute: a pin that changes only the *content* of a scenario passes every such guard and still
   tests the wrong thing.

   Wait for the stack by **asking the control API** whether it is ready, bounded by the startup
   timeout. After that, do not wait at all: a control endpoint that changes flag state owes the
   caller that the state is being served before it returns, so a suite that adds a delay of its own
   is covering for a backend that broke its side of the contract — see the control API's invariants.
   That holds for an adoption as much as for the shared harness: a backend that returns before it
   serves is a defect to fix in the backend, and compensating for it anywhere in the suite makes that
   adoption's results incomparable with every other adoption run against the same backend.
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

Guidance rather than a rule — a repository's pipeline is its own business — but the reasoning is the
same in every language, and leaving it unwritten produced four mechanisms and one unnoticed
consequence.

**An adoption suite is not a required gate while real gaps remain.** Its honest output is red: it
fails on provider defects that are filed and unfixed, on backend fixtures that do not exist yet, and
on capabilities the provider has not implemented. A red result is the suite working. Making it
block a merge forces someone to silence it, and the cheapest way to silence a conformance suite is
to stop asking the question — withdraw a capability, delete an assertion, or pin an older backend.

So **exclude it from the default build, and make the exclusion explicit.** Two mistakes to avoid,
both observed:

- **An exclusion that something else undoes.** The question is not whether an exclusion exists but
  whether any profile, target or job re-enables it. In one language a CI profile cleared the
  adopter's own exclusion property; in another the suite ran under a build tag applied to every
  module; in a third the default test task simply collected it. All four languages believed their
  suites were excluded and all four were running them, red, unwatched.
- **An exclusion nobody wrote down.** It is then indistinguishable from an oversight, and the next
  person to touch the pipeline removes it or duplicates it. State it where an adopter will read it.

Provide a single documented command that runs the suite deliberately, and **keep the adoption
typechecked by something that runs ordinarily**, even though it does not execute — a conformance
suite that has quietly stopped building against its own harness is a worse failure than one that
runs and fails.

"Something that runs ordinarily" rather than "the default build", because in at least one language
the default build cannot do it and never will. Where the ordinary build compiles what gets
*published*, it is configured for library code — no test globals, a different module target — and a
conformance adoption calling the test framework's own functions can never join it. There the
requirement is met by a typecheck scoped to the adoption instead, which is a further argument for
giving it a directory of its own: a directory nothing else occupies is something a typecheck can be
pointed at.

Two ways to fail this, both observed, and they are opposites. Excluding the adoption by path can
remove it from the build as well as from the run — silently, because nothing fails when nothing is
compiled. Or the reverse: removing an exclusion can pull the adoption *into* a build that cannot
compile it, which at least fails loudly. Whichever shape applies, assert it rather than assume it —
the cheap check is to introduce a deliberate compile error in the adoption and confirm the ordinary
build rejects it.

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

These decide what "promptly" and "timed out" mean, so they decide comparability. An implementation
**MUST** use these defaults and **MUST** let an adopter override each one.

| | default | bounds |
| --- | --- | --- |
| event | **12 s** | waiting for a lifecycle event a scenario asserts |
| ready | **30 s** | waiting for the provider to reach ready after registration |
| startup | **60 s** | bringing the whole backend stack up, before any scenario runs |

**An explicit `within {int}ms` in a step always wins over the event default.** The step states a bound
the scenario is about; the default is only for steps that state none.

### Registering the provider

A **fresh provider per scenario**, registered under a **domain derived from the suite name** that the
adopter never names, and replaced at the end of the scenario so the previous one is shut down and its
connections released.

Both halves matter. Registering once per suite would change what the lifecycle and reinitialisation
scenarios establish, since they assert against a provider whose state they control. A fresh *domain*
per scenario would leak: registering into a domain replaces and shuts down whatever was there, so a
new domain each time leaves every previous provider registered and running — for a provider holding a
network connection, one leaked connection per scenario.

### Reaching the provider from an extension step

An implementation that offers the extension point **MUST** also expose the client and provider under
test to an adopter's steps. Without it the only way to evaluate a flag from an extension step is to
build a second client, which resolves against a different provider — so the step tests the wiring and
reports success having asked the provider under test nothing.

### Run-integrity checks

Two failures are invisible from the results alone, so an implementation **MUST** fail the run on each:

- **A reserved tag reached a collected scenario.** The tag is reserved because nothing carries it; if
  something now does, the reservation has expired and the vocabulary is stale.
- **A declarable capability gates no collected scenario.** Either the assets are not the ones the
  implementation thinks it shipped, or a capability has outlived its scenarios — and in both cases a
  provider can declare it and be told nothing.
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
- **Normative status.** Nothing in this appendix is currently expressed as a numbered requirement.
  Whether the control API contract and the capability vocabulary should become normative sections is
  a decision for the TSC.
