# Evaluation Context

**Status**: [Experimental](../README.md#document-statuses)

## Overview

The `evaluation context` provides ambient information for the purposes of flag
evaluation. Contextual data may be used as the basis for targeting, including
rule-based evaluation, overrides for specific subjects, or fractional flag
evaluation.

### Fields

NOTE: Field casing is not specified, and should be chosen in accordance with
language idioms.

see: [types](../types.md)

##### Requirement 3.1

> The `evaluation context` structure **MUST** define an optional `targeting key`
> field of type string, identifying the subject of the flag evaluation.

The targeting key uniquely identifies the subject (end-user, or client service)
of a flag evaluation. Providers may require this field for fractional flag
evaluation, rules, or overrides targeting specific users. Such providers may
behave unpredictably if a targeting key is not specified at flag resolution.

##### Requirement 3.2

> The evaluation context **MUST** support the inclusion of custom fields, having
> keys of type `string`, and values of type
> `boolean | string | number | datetime | structure`.

see: [structure](../types.md#structure), [datetime](../types.md#datetime)
