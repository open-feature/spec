---
id: appendix-d
title: "Appendix D: Observability"
description: Conventions for OpenFeature telemetry signals
sidebar_position: 5
---

# Appendix D: Observability

This document describes conventions for extracting data from the OpenFeature SDK for use in telemetry signals.
It primarily focuses on providing recommendations for mapping well-known fields in OpenFeature to [OpenTelemetry feature-flag event records][otel-ff-events] and other semantic conventions.

## Evaluations

Flag evaluation telemetry comprises data resolved from the provider resolution (evaluation details and flag metadata) as well as metadata about the provider itself.
This is particularly relevant to telemetry-related [hooks](./sections/04-hooks.md).

### Evaluation Details

The following describes how fields on the [evaluation details](types.md#evaluation-details) are mapped to feature flag event records:

| Event Record Attribute          | Source Field or Derived Value from Evaluation Details | Requirement level             | Type        | Notes                                                                                                                 |
| ----------------------------- | ----------------------------------------------------- | ----------------------------- | ----------- | --------------------------------------------------------------------------------------------------------------------- |
| `feature_flag.key`            | `flag key`                                            | `Required`                    | `string`    | See: [flag key](./glossary.md#flag-key)                                                                               |
| `feature_flag.result.variant` | `variant`                                             | `Conditionally Required` [^1] | `string`    | See: [variant](./glossary.md#variant)                                                                                 |
| `feature_flag.result.value`   | `value`                                               | `Conditionally Required` [^2] | `undefined` | See: [value](./glossary.md#values)                                                                                    |
| `feature_flag.result.reason`  | `reason`                                              | `Recommended`                 | `string`    | See: [reason](./types.md#resolution-reason)                                                                           |
| `error.type`                  | `error code`                                          | `Conditionally Required` [^3] | `string`    | See: [error code](./types.md#error-code),                                                                             |
| `error.message`               | `error message`                                       | `Conditionally Required` [^3] | `string`    | A human-readable error message associated with a failed evaluation. For programmatic purposes, refer to `error code`. |

> [!NOTE]
> The `error.type` and `feature_flag.result.reason` enumerations use a lowercase "snake_case" convention (see [OpenTelemetry feature-flag event records][otel-ff-events]).
> OpenFeature [error codes](types.md#error-code) and [resolution reasons](./types.md#resolution-reason) should be transformed accordingly by integrations which include this data.

### Flag Metadata

The following describes how keys in [flag metadata](types.md#flag-metadata) are mapped to feature flag event records:

| Event Record Attribute      | Flag Metadata Key | Requirement level | Type     | Notes                                                                                                                                                                                           |
| ------------------------- | ----------------- | ----------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `feature_flag.context.id` | `contextId`       | `Recommended`     | `string` | The context identifier returned in the flag metadata uniquely identifies the subject of the flag evaluation. If not available, the [targeting key](./glossary.md#targeting-key) should be used. |
| `feature_flag.set.id`     | `flagSetId`       | `Recommended`     | `string` | A logical identifier for the [flag set](./glossary.md#flag-set).                                                                                                                                |
| `feature_flag.version`    | `version`         | `Recommended`     | `string` | A version string (format unspecified) for the flag or [flag set](./glossary.md#flag-set).                                                                                                       |

> [!NOTE]
> Keys in flag metadata use the "camelCase" casing convention, while the OpenTelemetry standard uses a namespaced "snake_case" convention.

### Provider Metadata

| Event Record Attribute         | Provider Metadata Field | Requirement level | Type     | Notes                                                                                            |
| ---------------------------- | ----------------------- | ----------------- | -------- | ------------------------------------------------------------------------------------------------ |
| `feature_flag.provider.name` | `name`                  | `Recommended`     | `string` | The name of the provider as defined in the `provider metadata`, available in the `hook context`. |

## Telemetry Hook Implementation Guide

This section provides guidance for implementing observability hooks that emit OpenTelemetry signals during feature flag evaluations. The recommendations ensure consistency across SDK implementations while allowing for language-specific idioms.

### Signal Emission Patterns

Telemetry hooks can emit OpenTelemetry signals in three distinct ways:

| Pattern              | Recommended | Advantages                                                                                                                                                         | Disadvantages                                                                                                                                          |
| -------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Span Events**      | ✓           | Associates flag evaluations with existing traces. Minimal overhead - no additional spans created. Maintains trace context relationships. Low cardinality impact.   | Requires an active span to function. Must gracefully handle absence of active span. Limited to span lifetime and context.                              |
| **Event Logging**    |             | Works independently without active spans. Aligns with OpenTelemetry's emerging direction. Suitable for environments without tracing. Simpler implementation model. | No automatic trace correlation. May require separate correlation mechanisms. Event logging standards still evolving.                                   |
| **Standalone Spans** |             | Complete distributed tracing per evaluation. Detailed timing information. Full span lifecycle control. Rich performance metrics.                                   | High cardinality - one span per evaluation. Increased overhead and resource usage. Potential performance impact at scale. More complex implementation. |

> [!NOTE]
> While span events are recommended for their low overhead and ease of use, OpenTelemetry is trending toward using log-based events instead of span events. SDK implementations may choose to prioritize event logging as standards evolve.

### Hook Lifecycle Implementation

#### Before Stage

The `before` hook stage is primarily used by standalone span hooks to create and store spans. When creating spans, it's recommended to store them in hook data using a consistent, documented key for easy retrieval in later stages.

#### Finally Stage

The `finally` hook stage is where telemetry signals are emitted with complete evaluation details. This stage should include all required and conditionally required attributes as defined in the evaluation details mapping table. It's also responsible for proper resource cleanup (like ending spans or closing connections) while ensuring it doesn't throw exceptions that could affect flag evaluation.

#### Error Stage

The `error` hook stage records exception information unless explicitly configured to exclude it. Implementations typically use OpenTelemetry's standard exception recording semantics (`recordException` for spans, exception log events for event logging). Configuration options like `excludeExceptions` allow users to control this behavior based on their needs.

### Attribute Transformations

When building telemetry attributes, implementations should extract and map well-known fields from flag metadata to their corresponding event record attributes as defined in the Flag Metadata table above. Remember to transform enumeration values (like error codes and reasons) from OpenFeature's uppercase format to OpenTelemetry's lowercase snake_case convention.

### Value Handling and Privacy

Flag values can contain sensitive data, so implementations should provide configuration to control whether values are included in telemetry signals. A safe default that protects potentially sensitive data is recommended. When values are included, they need to be serialized appropriately for the telemetry backend.

Consider providing mechanisms to redact or obfuscate sensitive flag values, along with size limits to prevent telemetry bloat. This helps balance observability needs with privacy and performance concerns.

### Configuration Options

For consistency across implementations, consider supporting a common set of configuration options:

- `excludeExceptions` (boolean): Whether to exclude exception recording in telemetry
- `includeValue` (boolean): Whether to include flag values in telemetry signals
- `maxValueLength` (integer): Maximum size for flag values before redaction
- `shouldRedact` (function): Custom function to determine value redaction

### Error Handling

Hooks should be designed to never throw exceptions that interrupt flag evaluation. Any internal errors can be logged at appropriate levels (debug/trace) without affecting application execution. While the OpenFeature SDK has error handling to capture hook exceptions, it's best practice to handle errors gracefully within the hook itself.

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

Feature flags in the OpenTelemetry semantic conventions are currently in development and are marked as experimental.
The following table describes the history of changes to the OpenTelemetry feature flag event records as it progresses towards a stable release.

| Original Field Name                     | New Field Name                | Semantic Convention Release                                                            |
| --------------------------------------- | ----------------------------- | -------------------------------------------------------------------------------------- |
| `feature_flag.variant`                  | `feature_flag.result.variant` | [v1.32.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.32.0) |
| `feature_flag.evaluation.reason`        | `feature_flag.result.reason`  | [v1.32.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.32.0) |
| `feature_flag.evaluation.error.message` | `error.message`               | [v1.33.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.33.0) |
| `feature_flag.provider_name`            | `feature_flag.provider.name`  | [v1.33.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.33.0) |
| `value`                                 | `feature_flag.result.value`   | [v1.34.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.34.0) |

## Footnotes

[^1]: The `variant` field should be included whenever possible as it represents the symbolic name of the flag's returned value (e.g., "on"/"off", "control"/"treatment"). Only omit if the provider doesn't supply this information.
[^2]: The `value` field is required when a `variant` is not available, and recommended when it is. Considerations should be made for large and/or sensitive values, which should be redacted or omitted prior to being captured in telemetry signals.
[^3]: Include `error.type` and `error.message`, if and only if an error occurred during a flag evaluation.

[otel-ff-events]: https://opentelemetry.io/docs/specs/semconv/feature-flags/feature-flags-logs/
