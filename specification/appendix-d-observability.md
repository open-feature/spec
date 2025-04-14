---
id: appendix-d
title: "Appendix D: Observability"
description: Conventions for OpenFeature telemetry signals 
sidebar_position: 5
---

# Appendix D: Observability

This document describes conventions for extracting data from the OpenFeature SDK for use in telemetry signals.
It primarily focuses on providing recommendations for mapping well-known fields in OpenFeature to [OpenTelemetry feature-flag log records][otel-ff-logs] and other semantic conventions.

## Evaluations

Flag evaluation telemetry comprises data resolved from the provider resolution (evaluation details and flag metadata) as well as metadata about the provider itself.
This is particularly relevant to telemetry-related [hooks](./sections/04-hooks.md).

### Evaluation Details

The following describes how fields on the [evaluation details](types.md#evaluation-details) are mapped to feature flag log records:

| Log Record Attribute          | Source Field or Derived Value from Evaluation Details | Requirement level             | Notes                                                                                                                 |
| ----------------------------- | ----------------------------------------------------- | ----------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `feature_flag.key`            | `flag key`                                            | `Required`                    | See: [flag key](./glossary.md#flag-key)                                                                               |
| `feature_flag.result.variant` | `variant`                                             | `Conditionally Required` [^2] | See: [variant](./glossary.md#variant)                                                                                 |
| `feature_flag.result.reason`  | `reason`                                              | `Recommended`                 | See: [reason](./types.md#resolution-reason)                                                                           |
| `error.type`                  | `error code`                                          | `Conditionally Required` [^1] | See: [error code](./types.md#error-code),                                                                             |
| `error.message`               | `error message`                                       | `Conditionally Required` [^1] | A human-readable error message associated with a failed evaluation. For programmatic purposes, refer to `error code`. |

> [!NOTE]
> The `error.type` and `feature_flag.result.reason` enumerations use a lowercase "snake_case" convention (see [OpenTelemetry feature-flag log records][otel-ff-logs]).
> OpenFeature [error codes](types.md#error-code) and [resolution reasons](./types.md#resolution-reason) should be transformed accordingly by integrations which include this data.

#### Flag Value

The flag value is required if the `feature_flag.result.variant` is not set (and optional otherwise), and is defined in a the event body:

| Body Field | Source Field from Evaluation Details | Requirement level             | Notes                                       |
| ---------- | ------------------------------------ | ----------------------------- | ------------------------------------------- |
| `value`    | `value`                              | `Conditionally Required` [^3] | The type of the `value` field is undefined. |

### Flag Metadata

The following describes how keys in [flag metadata](types.md#flag-metadata) are mapped to feature flag log records:

| Log Record Attribute      | Flag Metadata Key | Requirement level | Notes                                                                                                                                                                                           |
| ------------------------- | ----------------- | ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `feature_flag.context.id` | `contextId`       | `Recommended`     | The context identifier returned in the flag metadata uniquely identifies the subject of the flag evaluation. If not available, the [targeting key](./glossary.md#targeting-key) should be used. |
| `feature_flag.set.id`     | `flagSetId`       | `Recommended`     | A logical identifier for the [flag set](./glossary.md#flag-set).                                                                                                                                |
| `feature_flag.version`    | `version`         | `Recommended`     | A version string (format unspecified) for the flag or [flag set](./glossary.md#flag-set).                                                                                                       |

> [!NOTE]
> Keys in flag metadata use the "camelCase" casing convention, while the OpenTelemetry standard uses a namespaced "snake_case" convention.

### Provider Metadata

| Log Record Attribute         | Provider Metadata Field | Requirement level | Notes                                                                                            |
| ---------------------------- | ----------------------- | ----------------- | ------------------------------------------------------------------------------------------------ |
| `feature_flag.provider.name` | `name`                  | `Recommended`     | The name of the provider as defined in the `provider metadata`, available in the `hook context`. |

## History

Feature flags in the OpenTelemetry semantic conventions are currently in development and are marked as experimental.
The following table describes the history of changes to the OpenTelemetry feature flag log records as it progresses towards a stable release.

| Original Field Name                     | New Field Name                | Semantic Convention Release                                                            |
| --------------------------------------- | ----------------------------- | -------------------------------------------------------------------------------------- |
| `feature_flag.evaluation.error.message` | `error.message`               | [v1.32.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.32.0) |
| `feature_flag.variant`                  | `feature_flag.result.variant` | [v1.32.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.32.0) |
| `feature_flag.evaluation.reason`        | `feature_flag.result.reason`  | [v1.32.0](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.32.0) |
| `feature_flag.provider_name`            | `feature_flag.provider.name`  | Unreleased                                                                             |

## Footnotes

[^1]: Include if and only if an error occurred during a flag evaluation.
[^2]: The `variant` field is required if the `value` field is not set.
[^3]: The `value` field is required if the `variant` field is not set.

[otel-ff-logs]: https://opentelemetry.io/docs/specs/semconv/feature-flags/feature-flags-logs/
