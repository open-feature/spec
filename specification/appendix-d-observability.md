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

| Evaluation Details Field | Log Record Attribute                    | Notes                                                |
| ------------------------ | --------------------------------------- | ---------------------------------------------------- |
| `flag key`               | `feature_flag.key`                      | See: [flag key](./glossary.md#flag-key)              |
| `error code`             | `error.type`                            | See: [error code](./types.md#error-code)             |
| `variant`                | `feature_flag.variant`                  | See: [variant](./glossary.md#variant)                |
| `error message`          | `feature_flag.evaluation.error.message` | An error message associated with a failed evaluation |
| `reason`                 | `feature_flag.evaluation.reason`        | See: [reason](./types.md#resolution-reason)          |

> [!NOTE]  
> The `error.type` and `feature_flag.evaluation.reason` enumerations use a lowercase "snake_case" convention (see [OpenTelemetry feature-flag log records](https://opentelemetry.io/docs/specs/semconv/feature-flags/feature-flags-logs/)).
> OpenFeature [error codes](types.md#error-code) and [resolution reasons](./types.md#resolution-reason) should be transformed accordingly by integrations which include this data.

### Flag Metadata

The following describes how keys in [flag metadata](types.md#flag-metadata) are mapped to feature flag log records:

| Flag Metadata Key | Log Record Attribute      | Notes                                                                                                                                                                                           |
| ----------------- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `contextId`       | `feature_flag.context.id` | The context identifier returned in the flag metadata uniquely identifies the subject of the flag evaluation. If not available, the [targeting key](./glossary.md#targeting-key) should be used. |
| `flagSetId`       | `feature_flag.set.id`     | A logical identifier for the [flag set](./glossary.md#flag-set).                                                                                                                                |
| `flagSetVersion`  | `feature_flag.version`    | A version string (format unspecified) for the [flag set](./glossary.md#flag-set).                                                                                                               |

> [!NOTE]  
> Keys in flag metadata use the "camelCase" casing convention, while the OpenTelemetry standard uses a namespaced "snake_case" convention.

### Provider Metadata

| Provider Metadata Field | Log Record Attribute         | Notes                                                                                            |
| ----------------------- | ---------------------------- | ------------------------------------------------------------------------------------------------ |
| `name`                  | `feature_flag.provider_name` | The name of the provider as defined in the `provider metadata`, available in the `hook context`. |
      