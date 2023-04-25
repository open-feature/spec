---
title: Types and Data Structures
description: A description of types and data structures used within the OpenFeature specification.
sidebar_position: 2
---

# Types and Data Structures

## Overview

This document outlines some of the common types and data structures defined by OpenFeature and referenced elsewhere in this specification.

### Boolean

A logical true or false, as represented idiomatically in the implementation languages.

### String

A UTF-8 encoded string.

### Number

A numeric value of unspecified type or size. Implementation languages may further differentiate between integers, floating point numbers, and other specific numeric types and provide functionality as idioms dictate.

### Structure

Structured data, presented however is idiomatic in the implementation language, such as JSON or YAML.

### Datetime

A language primitive for representing a date and time, optionally including timezone information. If no timezone is specified, the date and time will be treated as UTC.

### Evaluation Details

A structure representing the result of the [flag evaluation process](./glossary.md#evaluating-flag-values), and made available in the [detailed flag resolution functions](./sections/01-flag-evaluation.md#14-detailed-flag-evaluation), containing the following fields:

- flag key (string, required)
- value (boolean | string | number | structure, required)
- error code ([error code](#error-code), optional)
- error message (string, optional)
- reason (string, optional)
- variant (string, optional)
- flag metadata ([flag metadata](#flag-metadata))

### Resolution Details

A structure which contains a subset of the fields defined in the `evaluation details`, representing the result of the provider's [flag resolution process](./glossary.md#resolving-flag-values), including:

- value (boolean | string | number | structure, required)
- error code ([error code](#error-code), optional)
- error message (string, optional)
- reason (string, optional)
- variant (string, optional)
- flag metadata ([flag metadata](#flag-metadata), optional)

A set of pre-defined reasons is enumerated below:

| Reason          | Explanation                                                                                           |
| --------------- |-------------------------------------------------------------------------------------------------------|
| STATIC          | The resolved value is static (no dynamic evaluation).                                                 |
| DEFAULT         | The resolved value fell back to a pre-configured value (no dynamic evaluation occurred or dynamic evaluation yielded no result).        |
| TARGETING_MATCH | The resolved value was the result of a dynamic evaluation, such as a rule or specific user-targeting. |
| SPLIT           | The resolved value was the result of pseudorandom assignment.                                         |
| CACHED          | The resolved value was retrieved from cache.                                                          |
| DISABLED        | The resolved value was the result of the flag being disabled in the management system.                |
| UNKNOWN         | The reason for the resolved value could not be determined.                                            |
| ERROR           | The resolved value was the result of an error.                                                        |

> NOTE: The `resolution details` structure is not exposed to the Application Author. It defines the data which Provider Authors must return when resolving the value of flags.

### Error Code

An enumerated error code represented idiomatically in the implementation language.

| Error Code            | Explanation                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------- |
| PROVIDER_NOT_READY    | The value was resolved before the provider was initialized.                                 |
| FLAG_NOT_FOUND        | The flag could not be found.                                                                |
| PARSE_ERROR           | An error was encountered parsing data, such as a flag configuration.                        |
| TYPE_MISMATCH         | The type of the flag value does not match the expected type.                                |
| TARGETING_KEY_MISSING | The provider requires a targeting key and one was not provided in the `evaluation context`. |
| INVALID_CONTEXT       | The `evaluation context` does not meet provider requirements.                               |
| GENERAL               | The error was for a reason not enumerated above.                                            |

### Evaluation Options

A structure containing the following fields:

- hooks (one or more [hooks](./sections/04-hooks.md), optional)

### Flag Metadata

A structure which supports definition of arbitrary properties, with keys of type `string`, and values of type `boolean`, `string`, or `number`.

This structure is populated by a provider for use by an [Application Author](./glossary.md#application-author) (via the [Evaluation API](./glossary.md#evaluation-api)) or an [Application Integrator](./glossary.md#application-integrator) (via [hooks](./sections/04-hooks.md)).

### Provider Status

An enumeration of possible provider states.

| Status    | Explanation                                                                     |
| --------- | ------------------------------------------------------------------------------- |
| NOT_READY | The provider has not been initialized.                                          |
| READY     | The provider has been initialized, and is able to reliably resolve flag values. |
| ERROR     | The provider is initialized but is not able to reliably resolve flag values.    |

### Provider Events

An enumeration of provider events.

| Event                          | Explanation                                                                                 |
| ------------------------------ | ------------------------------------------------------------------------------------------- |
| PROVIDER_READY                 | The provider is ready to perform flag evaluations.                                          |
| PROVIDER_ERROR                 | The provider signalled an error.                                                            |
| PROVIDER_CONFIGURATION_CHANGED | A change was made to the backend flag configuration.                                        |
