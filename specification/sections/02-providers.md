---
title: Provider
description: The specification that defines the responsibilities and behaviors of a provider.
toc_max_heading_level: 4
---

# Provider

## Overview

The `provider` API defines interfaces that Provider Authors can use to abstract a particular flag management system, thus enabling the use of the `evaluation API` by Application Authors.

Providers are the "translator" between the flag evaluation calls made in application code, and the flag management system that stores flags and in some cases evaluates flags. At a minimum, providers should implement some basic evaluation methods which return flag values of the expected type. In addition, providers may transform the [evaluation context](./03-evaluation-context.md) appropriately in order to be used in dynamic evaluation of their associated flag management system, provide insight into why evaluation proceeded the way it did, and expose configuration options for their associated flag management system. Hypothetical provider implementations might wrap a vendor SDK, embed an REST client, or read flags from a local file.

![Provider](../assets/images/provider.png)

### Feature Provider Interface

#### Requirement 2.1

> The provider interface **MUST** define a `metadata` member or accessor, containing a `name` field or accessor of type string, which identifies the provider implementation.

```typescript
provider.getMetadata().getName(); // "my-custom-provider"
```

#### Flag Value Resolution

`Providers` are implementations of the `feature provider` interface, which may wrap vendor SDKs, REST API clients, or otherwise resolve flag values from the runtime environment.

##### Requirement 2.2

> The `feature provider` interface **MUST** define methods to resolve flag values, with parameters `flag key` (string, required), `default value` (boolean | number | string | structure, required) and `evaluation context` (optional), which returns a `flag resolution` structure.

```typescript
// example flag resolution function
resolveBooleanValue(flagKey, defaultValue, context);
```

see: [flag resolution structure](../types.md#flag-resolution), [flag value resolution](../glossary.md#flag-value-resolution)

##### Condition 2.3

> The implementing language type system differentiates between strings, numbers, booleans and structures.

###### Conditional Requirement 2.3.1

> The `feature provider` interface **MUST** define methods for typed flag resolution, including boolean, numeric, string, and structure.

```typescript
// example boolean flag value resolution
ResolutionDetails resolveBooleanValue(string flagKey, boolean defaultValue, context: EvaluationContext);

// example string flag value resolution
ResolutionDetails resolveStringValue(string flagKey, string defaultValue, context: EvaluationContext);

// example number flag value resolution
ResolutionDetails resolveNumberValue(string flagKey, number defaultValue, context: EvaluationContext);

// example structure flag value resolution
ResolutionDetails resolveStructureValue(string flagKey, JsonObject defaultValue, context: EvaluationContext);
```

##### Requirement 2.4

> In cases of normal execution, the `provider` **MUST** populate the `flag resolution` structure's `value` field with the resolved flag value.

##### Requirement 2.5

> In cases of normal execution, the `provider` **SHOULD** populate the `flag resolution` structure's `variant` field with a string identifier corresponding to the returned flag value.

For example, the flag value might be `3.14159265359`, and the variant field's value might be `"pi"`.

The value of the variant field might only be meaningful in the context of the flag management system associated with the provider. For example, the variant may be a UUID corresponding to the variant in the flag management system, or an index corresponding to the variant in the flag management system.

##### Requirement 2.6

> The `provider` **SHOULD** populate the `flag resolution` structure's `reason` field with a string indicating the semantic reason for the returned flag value.

Possible values vary by provider, but might include such values as `"TARGETING_MATCH"`, `"SPLIT"`, `"DISABLED"`, `"DEFAULT"`, `"UNKNOWN"` or `"ERROR"`.

##### Requirement 2.7

> In cases of normal execution, the `provider` **MUST NOT** populate the `flag resolution` structure's `error code` field, or otherwise must populate it with a null or falsy value.

##### Requirement 2.8

> In cases of abnormal execution, the `provider` **MUST** indicate an error using the idioms of the implementation language, with an associated error code having possible values `"PROVIDER_NOT_READY"`, `"FLAG_NOT_FOUND"`, `"PARSE_ERROR"`, `"TYPE_MISMATCH"`, or `"GENERAL"`.

The provider might throw an exception, return an error, or populate the `error code` object on the returned `flag resolution` structure to indicate a problem during flag value resolution.

##### Condition 2.9

> The implementation language supports generics (or an equivalent feature).

###### Conditional Requirement 2.9.1

> The `flag resolution` structure **SHOULD** accept a generic argument (or use an equivalent language feature) which indicates the type of the wrapped `value` field.

```typescript
// example boolean flag value resolution with generic argument
ResolutionDetails<boolean> resolveBooleanValue(string flagKey, boolean defaultValue, context: EvaluationContext);

// example string flag value resolution with generic argument
ResolutionDetails<string> resolveStringValue(string flagKey, string defaultValue, context: EvaluationContext);

// example number flag value resolution with generic argument
ResolutionDetails<number> resolveNumberValue(string flagKey, number defaultValue, context: EvaluationContext);

// example structure flag value resolution with generic argument
ResolutionDetails<MyStruct> resolveStructureValue(string flagKey, MyStruct defaultValue, context: EvaluationContext);
```

#### Provider hooks

A `provider hook` exposes a mechanism for `provider authors` to register [`hooks`](./04-hooks.md) to tap into various stages of the flag evaluation lifecycle. These hooks can be used to perform side effects and mutate the context for purposes of the provider. Provider hooks are not configured or controlled by the `application author`.

##### Requirement 2.10

> The provider interface **MUST** define a `provider hook` mechanism which can be optionally implemented in order to add `hook` instances to the evaluation life-cycle.

```
class MyProvider implements Provider {
  //...

  readonly hooks: Hook[] = [new MyProviderHook()];

  // ..or alternatively..
  getProviderHooks(): Hook[]  {
    return [new MyProviderHook()];
  }

  //...
}
```
