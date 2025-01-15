---
id: appendix-d
title: "Appendix D: Observability"
description: Conventions for OpenFeature telemetry signals 
sidebar_position: 5
---

# Appendix D: Observability

This document describes conventions for extracting data from the OpenFeature SDK for use in telemetry signals.
It primarily focuses on providing recommendations for mapping well-known fields in OpenFeature to [OpenTelemetry feature-flag log records](https://opentelemetry.io/docs/specs/semconv/feature-flags/feature-flags-logs/) and other semantic conventions.

## Evaluations

Flag evaluation telemetry comprises data resolved from the provider resolution (evaluation details and flag metadata) as well as metadata about the provider itself.
This is particularly relevant to telemetry-related [hooks](./sections/04-hooks.md).

### Evaluation Details

The following describes how fields on the [evaluation details](types.md#evaluation-details) are mapped to feature flag log records:

| Log Record Attribute                    | Source Field or Derived Value from Evaluation Details                                                                                                                             | Notes                                                                                                                 |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `feature_flag.key`                      | `flag key`                                                                                                                                                                        | See: [flag key](./glossary.md#flag-key)                                                                               |
| `error.type`                            | `error code`                                                                                                                                                                      | See: [error code](./types.md#error-code)                                                                              |
| `feature_flag.variant`                  | `variant`                                                                                                                                                                         | See: [variant](./glossary.md#variant)                                                                                 |
| `feature_flag.evaluation.error.message` | `error message`                                                                                                                                                                   | A human-readable error message associated with a failed evaluation. For programmatic purposes, refer to `error code`. |
| `feature_flag.evaluation.reason`        | `reason`                                                                                                                                                                          | See: [reason](./types.md#resolution-reason)                                                                           |
| `feature_flag.evaluation.value.type`    | One of `"array"`, `"boolean"`, `"byte_array"`, `"float"`, `"int"`, `"map"`, `"null"`, `"string"` or `"unknown"`, representing the type of the `evaluation details'` `value` field | See: [reason](./types.md#resolution-reason)                                                                           |

> [!NOTE]  
> The `error.type` and `feature_flag.evaluation.reason` enumerations use a lowercase "snake_case" convention (see [OpenTelemetry feature-flag log records](https://opentelemetry.io/docs/specs/semconv/feature-flags/feature-flags-logs/)).
> OpenFeature [error codes](types.md#error-code) and [resolution reasons](./types.md#resolution-reason) should be transformed accordingly by integrations which include this data.

#### Flag Value

The flag value is required if the `feature_flag.variant` is not set (and optional otherwise), and is defined in a the event body:

| Body Field | Source Field from Evaluation Details | Notes                                       |
| ---------- | ------------------------------------ | ------------------------------------------- |
| `value`    | `value`                              | The type of the `value` field is undefined. |

### Flag Metadata

The following describes how keys in [flag metadata](types.md#flag-metadata) are mapped to feature flag log records:

| Log Record Attribute      | Flag Metadata Key | Notes                                                                                                                                                                                           |
| ------------------------- | ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `feature_flag.context.id` | `contextId`       | The context identifier returned in the flag metadata uniquely identifies the subject of the flag evaluation. If not available, the [targeting key](./glossary.md#targeting-key) should be used. |
| `feature_flag.set.id`     | `flagSetId`       | A logical identifier for the [flag set](./glossary.md#flag-set).                                                                                                                                |
| `feature_flag.version`    | `version`         | A version string (format unspecified) for the flag or [flag set](./glossary.md#flag-set).                                                                                                       |

> [!NOTE]  
> Keys in flag metadata use the "camelCase" casing convention, while the OpenTelemetry standard uses a namespaced "snake_case" convention.

### Provider Metadata

| Log Record Attribute         | Provider Metadata Field | Notes                                                                                            |
| ---------------------------- | ----------------------- | ------------------------------------------------------------------------------------------------ |
| `feature_flag.provider_name` | `name`                  | The name of the provider as defined in the `provider metadata`, available in the `hook context`. |
