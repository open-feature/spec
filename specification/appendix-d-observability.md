---
id: appendix-d
title: "Appendix D: Observability"
description: Conventions for OpenFeature telemetry signals
sidebar_position: 5
---

# Appendix D: Observability

This document describes conventions for extracting data from the OpenFeature SDK for use in telemetry signals. It primarily focuses on providing recommendations for mapping well-known fields in OpenFeature to [OpenTelemetry feature-flag event records][otel-ff-events] and other semantic conventions.

<!-- Generated sections are maintained by make telemetry-generate; do not edit their contents directly. -->

<!-- weaver template:version.md.j2 .dependency_graph[.schema_url][] | select(startswith("https://opentelemetry.io/schemas/")) | {version: (split("/") | last)} -->

The attribute mappings target [OpenTelemetry semantic conventions v1.44.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.44.0).

<!-- endweaver -->

This repository's telemetry registry (`telemetry/registry/feature_flags.yaml`) refines the upstream event with OpenFeature requirements and source mappings. The event reference and mapping tables below are generated from the same resolved definition, including inherited OpenTelemetry descriptions and notes.

## Feature Flag Evaluation Event

<!-- semconv refinements.events.feature_flag.evaluation(tag=event) -->

**Event name:** `feature_flag.evaluation`

**Stability:** Release Candidate

**Requirement level:** Recommended

Defines feature flag evaluation as an event.

A `feature_flag.evaluation` event SHOULD be emitted whenever a feature flag value is evaluated, which may happen many times over the course of an application lifecycle. For example, a website A/B testing different animations may evaluate a flag each time a button is clicked. A `feature_flag.evaluation` event is emitted on each evaluation even if the result is the same.

| Attribute | Stability | Requirement Level | Type | Description | Example Values |
| --- | --- | --- | --- | --- | --- |
| `feature_flag.key` | Release Candidate | Required | `string` | The lookup key of the feature flag. | `["logo-color"]` |
| `error.type` [^feature_flag.evaluation-error.type] | Stable | Conditionally Required | `string` | Describes a class of error the operation ended with. | `["provider_not_ready","targeting_key_missing","provider_fatal","general"]` |
| `feature_flag.error.message` [^feature_flag.evaluation-feature_flag.error.message] | Release Candidate | Conditionally Required | `string` | A message providing more detail about an error that occurred during feature flag evaluation in human-readable form. | `["Unexpected input type: string","The user has exceeded their storage quota"]` |
| `feature_flag.result.value` [^feature_flag.evaluation-feature_flag.result.value] | Release Candidate | Conditionally Required | `any` | The evaluated value of the feature flag. | `["#ff0000",true,3]` |
| `feature_flag.result.variant` [^feature_flag.evaluation-feature_flag.result.variant] | Release Candidate | Conditionally Required | `string` | A semantic identifier for an evaluated flag value. | `["red","true","on"]` |
| `feature_flag.context.id` | Release Candidate | Recommended | `string` | The unique identifier for the flag evaluation context. For example, the targeting key. | `["5157782b-2203-4c80-a857-dbbd5e7761db"]` |
| `feature_flag.provider.name` | Release Candidate | Recommended | `string` | Identifies the feature flag provider. | `["Flag Manager"]` |
| `feature_flag.result.reason` [^feature_flag.evaluation-feature_flag.result.reason] | Release Candidate | Recommended | `string` | The reason code which shows how a feature flag value was determined. | `["static","targeting_match","error","default"]` |
| `feature_flag.set.id` | Release Candidate | Recommended | `string` | The identifier of the [flag set](https://openfeature.dev/specification/glossary/#flag-set) to which the feature flag belongs. | `["proj-1","ab98sgs","service1/dev"]` |
| `feature_flag.version` | Release Candidate | Recommended | `string` | The version of the ruleset used during the evaluation. This may be any stable value which uniquely identifies the ruleset. | `["1","01ABCDEF"]` |

[^feature_flag.evaluation-error.type]:
    **Conditionally Required:** If and only if an error occurred during flag evaluation.

    If one of these values applies, then it MUST be used; otherwise, a custom value MAY be used.

    | Value | Description | Stability |
    | --- | --- | --- |
    | `flag_not_found` | The flag could not be found. | ![Release Candidate](https://img.shields.io/badge/-rc-mediumorchid) |
    | `invalid_context` | The evaluation context does not meet provider requirements. | ![Release Candidate](https://img.shields.io/badge/-rc-mediumorchid) |
    | `parse_error` | An error was encountered parsing data, such as a flag configuration. | ![Release Candidate](https://img.shields.io/badge/-rc-mediumorchid) |
    | `provider_fatal` | The provider has entered an irrecoverable error state. | ![Release Candidate](https://img.shields.io/badge/-rc-mediumorchid) |
    | `provider_not_ready` | The value was resolved before the provider was initialized. | ![Release Candidate](https://img.shields.io/badge/-rc-mediumorchid) |
    | `targeting_key_missing` | The provider requires a targeting key and one was not provided in the evaluation context. | ![Release Candidate](https://img.shields.io/badge/-rc-mediumorchid) |
    | `type_mismatch` | The type of the flag value does not match the expected type. | ![Release Candidate](https://img.shields.io/badge/-rc-mediumorchid) |
    | `general` | The error was for a reason not enumerated above. | ![Release Candidate](https://img.shields.io/badge/-rc-mediumorchid) |

    **Known values:**

    | Value | Description |
    | --- | --- |
    | `"_OTHER"` | A fallback error value to be used when the instrumentation doesn't define a custom value. |

[^feature_flag.evaluation-feature_flag.error.message]:
    **Conditionally Required:** If and only if an error occurred during flag evaluation.

    Should not simply duplicate the value of `error.type`, but should provide more context. For example, if `error.type` is `invalid_context` the `feature_flag.error.message` may enumerate which context keys are missing or invalid.

[^feature_flag.evaluation-feature_flag.result.value]:
    **Conditionally Required:** If a variant is not available. Otherwise, recommended.

    Considerations should be made for large and/or sensitive values, which should be redacted or omitted prior to being captured in telemetry signals.

[^feature_flag.evaluation-feature_flag.result.variant]:
    **Conditionally Required:** If feature flag provider supplies a variant or equivalent concept.

    The `variant` field should be included whenever possible as it represents the symbolic name of the flag's returned value (e.g., "on"/"off", "control"/"treatment"). Only omit if the provider doesn't supply this information.

[^feature_flag.evaluation-feature_flag.result.reason]:
    **Known values:**

    | Value | Description |
    | --- | --- |
    | `"static"` | The resolved value is static (no dynamic evaluation). |
    | `"default"` | The resolved value fell back to a pre-configured value (no dynamic evaluation occurred or dynamic evaluation yielded no result). |
    | `"targeting_match"` | The resolved value was the result of a dynamic evaluation, such as a rule or specific user-targeting. |
    | `"split"` | The resolved value was the result of pseudorandom assignment. |
    | `"cached"` | The resolved value was retrieved from cache. |
    | `"disabled"` | The resolved value was the result of the flag being disabled in the management system. |
    | `"unknown"` | The reason for the resolved value could not be determined. |
    | `"stale"` | The resolved value is non-authoritative or possibly out of date |
    | `"error"` | The resolved value was the result of an error. |

<!-- endsemconv -->

## Attribute Mapping

Flag evaluation telemetry comprises data resolved from the provider resolution (evaluation details and flag metadata) as well as metadata about the provider itself. This is particularly relevant to telemetry-related [hooks](./sections/04-hooks.md).

### Evaluation Details

The following describes how fields on the [evaluation details](types.md#evaluation-details) are mapped to feature flag event records:

<!-- semconv refinements.events.feature_flag.evaluation(tag=evaluation) -->

| Event Record Attribute | Source Field or Derived Value from Evaluation Details | OpenFeature Guidance |
| --- | --- | --- |
| `feature_flag.key` | `flag key` | See: [flag key](./glossary.md#flag-key) |
| `error.type` | `error code` | See: [error code](./types.md#error-code) |
| `feature_flag.error.message` | `error message` | For programmatic purposes, refer to [error code](./types.md#error-code). |
| `feature_flag.result.value` | `value` | See: [value](./glossary.md#values) |
| `feature_flag.result.variant` | `variant` | See: [variant](./glossary.md#variant) |
| `feature_flag.result.reason` | `reason` | See: [reason](./types.md#resolution-reason) |

<!-- endsemconv -->

> [!NOTE] The `error.type` and `feature_flag.result.reason` enumerations use a lowercase "snake_case" convention (see [OpenTelemetry feature-flag event records][otel-ff-events]). OpenFeature [error codes](types.md#error-code) and [resolution reasons](./types.md#resolution-reason) should be transformed accordingly by integrations which include this data.

### Flag Metadata

The following describes how keys in [flag metadata](types.md#flag-metadata) are mapped to feature flag event records:

<!-- semconv refinements.events.feature_flag.evaluation(tag=flag_metadata) -->

| Event Record Attribute | Flag Metadata Key | OpenFeature Guidance |
| --- | --- | --- |
| `feature_flag.context.id` | `contextId` | The context identifier returned in the flag metadata uniquely identifies the subject of the flag evaluation. If not available, the [targeting key](./glossary.md#targeting-key) should be used. |
| `feature_flag.set.id` | `flagSetId` | A logical identifier for the [flag set](./glossary.md#flag-set). |
| `feature_flag.version` | `version` | A version string (format unspecified) for the flag or [flag set](./glossary.md#flag-set). |

<!-- endsemconv -->

> [!NOTE] Keys in flag metadata use the "camelCase" casing convention, while the OpenTelemetry standard uses a namespaced "snake_case" convention.

### Provider Metadata

<!-- semconv refinements.events.feature_flag.evaluation(tag=provider_metadata) -->

| Event Record Attribute | Provider Metadata Field | OpenFeature Guidance |
| --- | --- | --- |
| `feature_flag.provider.name` | `name` | The name of the provider as defined in the `provider metadata`, available in the `hook context`. |

<!-- endsemconv -->

## Telemetry Hook Implementation Guide

This section provides guidance for implementing observability hooks that emit OpenTelemetry signals during feature flag evaluations. The recommendations ensure consistency across SDK implementations while allowing for language-specific idioms.

### Signal Emission Patterns

Telemetry hooks can emit OpenTelemetry signals in three distinct ways:

| Pattern | Advantages | Disadvantages |
| --- | --- | --- |
| **Span Events**<br />![recommended](https://img.shields.io/badge/recommended-green) | <ul><li>Leverages existing trace configuration and tooling</li><li>Minimal overhead, no additional spans created</li><li>Maintains trace context relationships</li><li>Simpler than creating spans</li></ul> | <ul><li>Requires an active span to function</li><li>Must gracefully handle absence of active span</li><li>Limited to span lifetime and context.</li></ul> |
| **Event Logging** | <ul><li>Works independently without active spans</li><li>Aligns with OpenTelemetry's emerging direction</li><li>Suitable for environments without tracing</li><li>Simpler implementation model</li></ul> | <ul><li>Requires an event exporter to be configured</li><li>Processed and stored separately from spans</li><li>Event logging standards still evolving</li></ul> |
| **Standalone Spans** | <ul><li>Distributed traces contain every evaluation</li><li>Detailed timing information</li><li>Full span lifecycle control</li></ul> | <ul><li>Creates one span per evaluation</li><li>May clutter trace visualizations</li><li>Increased overhead and resource usage</li><li>Potential performance impact at scale</li><li>More complex implementation</li></ul> |

> [!NOTE] While span events are recommended for their low overhead and ease of use, OpenTelemetry is trending toward using log-based events instead of span events. Please refer to the [OpenTelemetry Span Event Deprecation Plan][otel-span-event-deprecation-plan] for more details.

### Hook Lifecycle Implementation

#### Before Stage

The `before` hook stage is primarily used by standalone span hooks to create and store spans. When creating spans, it's recommended to use the name `feature_flag.evaluation` and store them in hook data using a consistent, documented key for easy retrieval in later stages.

#### Error Stage

The `error` hook stage records exception information unless explicitly configured to exclude it. Implementations typically use [OpenTelemetry's standard exception][otel-record-error] recording semantics (`recordException` for spans, exception log events for event logging). Configuration options like `excludeExceptions` allow users to control this behavior based on their needs.

#### Finally Stage

The `finally` hook stage is where telemetry signals are emitted with complete evaluation details. This stage should include all required and conditionally required attributes as defined in the event reference above. It's also responsible for proper resource cleanup (like ending spans or closing connections).

### Attribute Transformations

When building telemetry attributes, implementations should extract and map well-known fields from flag metadata to their corresponding event record attributes as defined in the Flag Metadata table above. Remember to transform enumeration values (like error codes and reasons) from OpenFeature's uppercase format to OpenTelemetry's lowercase snake_case convention.

### Value Handling and Privacy

Flag values can contain large or sensitive data, so implementations should provide configuration to control whether values are included in telemetry signals. It's the users' responsibility to manage this configuration. When values are included, they need to be serialized appropriately for OpenTelemetry.

Consider providing mechanisms to redact or obfuscate sensitive flag values, along with size limits to prevent telemetry bloat. This helps balance observability needs with privacy and performance concerns.

### Configuration Options

For consistency across implementations, consider supporting a common set of configuration options:

- `attributeMapper` (function): Custom function to add additional attributes to the signal
- `excludeAttributes` (list): List of attribute keys to exclude from the signal
- `excludeExceptions` (boolean): Whether to omit [exception details][otel-exception-details] from error signals
- `eventMutator` (function): Custom function to modify event attributes before sending

### Error Handling

Hooks should be designed to never throw exceptions that interrupt flag evaluation. Any internal errors can be logged at appropriate levels (debug/trace) without affecting application execution.

### Implementation Patterns

#### Common Base Class

In object-oriented languages, you might find it helpful to create a base hook class containing common functionality shared across all telemetry hook types. This typically includes:

- Shared configuration options
- Attribute building and transformation methods
- Enumeration format conversion
- Metadata extraction logic
- Logger instances for internal debugging

This pattern can reduce code duplication and ensure consistency across different hook implementations, though it's not required.

## History

Feature flags in the OpenTelemetry semantic conventions are currently in development and are marked as a release candidate. The following table describes the history of changes to the OpenTelemetry feature flag event records as it progresses towards a stable release.

| Original Field Name | New Field Name | Semantic Convention Release |
| --- | --- | --- |
| `feature_flag.variant` | `feature_flag.result.variant` | [v1.32.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.32.0) |
| `feature_flag.evaluation.reason` | `feature_flag.result.reason` | [v1.32.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.32.0) |
| `feature_flag.evaluation.error.message` | `error.message` | [v1.33.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.33.0) |
| `feature_flag.provider_name` | `feature_flag.provider.name` | [v1.33.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.33.0) |
| `value` | `feature_flag.result.value` | [v1.34.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.34.0) |
| `error.message` | `feature_flag.error.message` | [v1.40.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.40.0) |

[otel-ff-events]: https://opentelemetry.io/docs/specs/semconv/feature-flags/feature-flags-logs/
[otel-span-event-deprecation-plan]: https://github.com/open-telemetry/opentelemetry-specification/blob/main/oteps/4430-span-event-api-deprecation-plan.md
[otel-record-error]: https://opentelemetry.io/docs/specs/semconv/general/recording-errors/
[otel-exception-details]: https://opentelemetry.io/docs/specs/semconv/exceptions/
