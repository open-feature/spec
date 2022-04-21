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

### Evaluation Details

A structure representing the result of the [flag evaluation process](./glossary.md#evaluating-flag-values), and made available in the [detailed flag resolution functions](./flag-evaluation/flag-evaluation.md#detailed-flag-evaluation), containing the following fields:

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

\*NOTE: The `resolution details` structure is not exposed to the Application Author. It defines the data which Provider Authors must return when resolving the value of flags.

### Evaluation Options

A structure containing the following fields:

- hooks (one or more [hooks](./flag-evaluation/hooks.md), optional)
