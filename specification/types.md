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

A language primitive for representing a date and time, including timezone information.

### Evaluation Details

A structure representing the result of the [flag evaluation process](./glossary.md#evaluating-flag-values), and made available in the [detailed flag resolution functions](./sections/01-flag-evaluation.md#detailed-flag-evaluation), containing the following fields:

- flag key (string, required)
- value (boolean | string | number | structure, required)
- error code (string, optional)
- reason (string, optional)
- variant (string, optional)

### Resolution Details

A structure which contains a subset of the fields defined in the `evaluation details`, representing the result of the provider's [flag resolution process](./glossary.md#resolving-flag-values), including:

- value (boolean | string | number | structure, required)
- error code (string, optional)
- reason (string, optional)
- variant (string, optional)

A set of pre-defined reasons is enumerated below:

| Reason          | Explanation                                                                                           |
| --------------- | ----------------------------------------------------------------------------------------------------- |
| DEFAULT         | The resolved value was configured statically, or otherwise fell back to a pre-configured value.       |
| TARGETING_MATCH | The resolved value was the result of a dynamic evaluation, such as a rule or specific user-targeting. |
| SPLIT           | The resolved value was the result of pseudorandom assignment.                                         |
| DISABLED        | The resolved value was the result of the flag being disabled in the management system.                |
| UNKNOWN         | The reason for the resolved value could not be determined.                                            |
| ERROR           | The resolved value was the result of an error.                                                        |

> NOTE: The `resolution details` structure is not exposed to the Application Author. It defines the data which Provider Authors must return when resolving the value of flags.

### Evaluation Options

A structure containing the following fields:

- hooks (one or more [hooks](./sections/04-hooks.md), optional)
