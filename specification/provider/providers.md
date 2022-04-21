# Provider

## Overview

The `provider` API defines interfaces that Provider Authors can use to abstract a particular flag management system, thus enabling the use of the `evaluation API` by Application Authors.

### Feature Provider Interface

##### Requirement 2.1

> The provider interface **MUST** define a `name` field or accessor, which identifies the provider implementation.

#### Flag Value Resolution

`Providers` are implementations of the `feature provider` interface, which may wrap vendor SDKs, REST API clients, or otherwise resolve flag values from the runtime environment.

##### Requirement 2.2

> The `feature provider` interface **MUST** define methods to resolve flag values, with parameters `flag key` (string, required), `default value` (boolean | number | string | structure, required), `evaluation context` (optional), and `evaluation options` (optional), which returns a `flag resolution` structure.

```
// example flag resolution function
resolveBooleanValue(flagKey, defaultValue, context, options);
```

See: [flag resolution structure](../types.md#flag-resolution), [flag value resolution](../glossary.md#flag-value-resolution)

##### Condition 2.3

> The implementing language type system differentiates between strings, numbers, booleans and structures.
>
> ##### Conditional Requirement 2.3.1
>
> > The `feature provider` interface **MUST** define methods for typed flag resolution, including boolean, numeric, string, and structure.

```
// example boolean flag value resolution
ResolutionDetails resolveBooleanValue(string flagKey, boolean defaultValue, context: EvaluationContext, options: FlagEvaluationOptions);

// example string flag value resolution
ResolutionDetails resolveStringValue(string flagKey, string defaultValue, context: EvaluationContext, options: FlagEvaluationOptions);

// example number flag value resolution
ResolutionDetails resolveNumberValue(string flagKey, number defaultValue, context: EvaluationContext, options: FlagEvaluationOptions);

// example structure flag value resolution
ResolutionDetails resolveStructureValue(string flagKey, JsonObject defaultValue, context: EvaluationContext, options: FlagEvaluationOptions);
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
>
> ##### Conditional Requirement 2.9.1
>
> > The `flag resolution` structure **SHOULD** accept a generic argument (or use an equivalent language feature) which indicates the type of the wrapped `value` field.

```
// example boolean flag value resolution with generic argument
ResolutionDetails<boolean> resolveBooleanValue(string flagKey, boolean defaultValue, context: EvaluationContext, options: FlagEvaluationOptions);

// example string flag value resolution with generic argument
ResolutionDetails<string> resolveStringValue(string flagKey, string defaultValue, context: EvaluationContext, options: FlagEvaluationOptions);

// example number flag value resolution with generic argument
ResolutionDetails<number> resolveNumberValue(string flagKey, number defaultValue, context: EvaluationContext, options: FlagEvaluationOptions);

// example structure flag value resolution with generic argument
ResolutionDetails<MyStruct> resolveStructureValue(string flagKey, MyStruct defaultValue, context: EvaluationContext, options: FlagEvaluationOptions);
```

#### Context Transformation

Feature flag management systems often define structures representing arbitrary contextual data pertaining to the runtime, user, or application. The context transformer defines a simple interface to transform the OpenFeature `evaluation context` to such a structure, mapping values appropriately.

See [evaluation context](../evaluation-context/evaluation-context.md).

##### Requirement 2.10

> The provider interface **MAY** define a `context transformer` method or function, which can be optionally implemented in order to transform the `evaluation context` prior to flag value resolution.

The OpenFeature `client` might apply the transformer function before passing the returned value (the `transformed context`) to the provider resolution methods, thus allowing the provider implementation to avoid implementing and calling such transformation logic repeatedly in flag value resolution methods.

```
class MyProvider implements Provider {
  //...

  // implementation of context transformer
  MyProviderContext transformContext(EvaluationContext context) {
    return new MyProviderContext(context.email, context.ip, context.httpMethod);
  }

  //...
}
```

See [evaluation context](../evaluation-context/evaluation-context.md), [flag evaluation](./../flag-evaluation/flag-evaluation.md#flag-evaluation).

##### Condition 2.11

> The implementation language supports generics (or an equivalent feature).
>
> ##### Conditional Requirement 2.11.1
>
> > If the implementation includes a `context transformer`, the provider **SHOULD** accept a generic argument (or use an equivalent language feature) indicating the type of the transformed context.
>
> If such type information is supplied, more accurate type information can be supplied in the flag resolution methods.

```
// an example implementation in a language supporting interfaces, classes, and generics
// T represents a generic argument for the type of the transformed context
interface Provider<T> {

  //...

  // context transformer signature
  T transformContext(EvaluationContext context);

  //...

  // flag resolution methods context parameter type corresponds to class-generic
  boolean resolveBooleanValue (string flagKey, boolean defaultValue, T transformedContext, EvaluationOptions options);

  //...

}
```
