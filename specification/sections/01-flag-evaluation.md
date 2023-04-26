---
title: Flag Evaluation API
description: The specification that defines the developer facing feature flag evaluation API.
toc_max_heading_level: 4
---

# 1. Flag Evaluation API

[![hardening](https://img.shields.io/static/v1?label=Status&message=hardening&color=yellow)](https://github.com/open-feature/spec/tree/main/specification#hardening)

## Overview

The `evaluation API` allows for the evaluation of feature flag values, independent of any flag control plane or vendor. In the absence of a [provider](./02-providers.md) the `evaluation API` uses the "No-op provider", which simply returns the supplied default flag value.

### 1.1. API Initialization and Configuration

#### Requirement 1.1.1

> The `API`, and any state it maintains **SHOULD** exist as a global singleton, even in cases wherein multiple versions of the `API` are present at runtime.

It's important that multiple instances of the `API` not be active, so that state stored therein, such as the registered `provider`, static global `evaluation context`, and globally configured `hooks` allow the `API` to behave predictably. This can be difficult in some runtimes or languages, but implementors should make their best effort to ensure that only a single instance of the `API` is used.

### Setting a provider

#### Requirement 1.1.2.1

> The `API` **MUST** define a `provider mutator`, a function to set the default `provider`, which accepts an API-conformant `provider` implementation.

```typescript
// example provider mutator
OpenFeature.setProvider(new MyProvider());
```

This provider is used if there is not a more specific client name binding. (see later requirements).

See [provider](./02-providers.md) for details.

#### Requirement 1.1.2.2

> The `provider mutator` function **MUST** invoke the `initialize` function on the newly registered provider before using it to resolve flag values.

The `provider's` readiness can state can be maintained in it's `ready` member.

See [provider initialization](./02-providers.md#24-initialization).

#### Requirement 1.1.2.3

>  The `provider mutator` function **MUST** invoke the `shutdown` function on the previously registered provider once it's no longer being used to resolve flag values.

Setting a new provider means the previous provider is no longer in use, and should therefor be disposed of using it's `shutdown` function.

see: [shutdown](./02-providers.md#26-shutdown), [setting a provider](#setting-a-provider)

#### Requirement 1.1.3

> The `API` **MUST** provide a function to bind a given `provider` to one or more client `name`s. If the client-name already has a bound provider, it is overwritten with the new mapping.

```java
OpenFeature.setProvider("client-name", new MyProvider());
```

#### Requirement 1.1.4

> The `API` **MUST** provide a function to add `hooks` which accepts one or more API-conformant `hooks`, and appends them to the collection of any previously added hooks. When new hooks are added, previously added hooks are not removed.

```typescript
// example hook attachment
OpenFeature.addHooks([new MyHook()]);
```

See [hooks](./04-hooks.md) for details.

#### Requirement 1.1.5

> The API **MUST** provide a function for retrieving the metadata field of the configured `provider`.

```typescript
// example provider accessor
OpenFeature.getProviderMetadata();
```

See [provider](./02-providers.md) for details.

#### Requirement 1.1.6

> The `API` **MUST** provide a function for creating a `client` which accepts the following options:
>
> - name (optional): A logical string identifier for the client.

```typescript
// example client creation and retrieval
OpenFeature.getClient({
  name: "my-openfeature-client",
});
```

The name is a logical identifier for the client.

#### Requirement 1.1.7

> The client creation function **MUST NOT** throw, or otherwise abnormally terminate.

Clients may be created in critical code paths, and even per-request in server-side HTTP contexts. Therefore, in keeping with the principle that OpenFeature should never cause abnormal execution of the first party application, this function should never throw. Abnormal execution in initialization should instead occur during provider registration.

### 1.2. Client Usage

#### Requirement 1.2.1

> The client **MUST** provide a method to add `hooks` which accepts one or more API-conformant `hooks`, and appends them to the collection of any previously added hooks. When new hooks are added, previously added hooks are not removed.

```typescript
// example hook attachment
client.addHooks([new MyHook()]);
```

See [hooks](./04-hooks.md) for details.

#### Requirement 1.2.2

> The client interface **MUST** define a `metadata` member or accessor, containing an immutable `name` field or accessor of type string, which corresponds to the `name` value supplied during client creation.

```typescript
client.getMetadata().getName(); // "my-client"
```

### 1.3. Flag Evaluation

[![hardening](https://img.shields.io/static/v1?label=Status&message=hardening&color=yellow)](https://github.com/open-feature/spec/tree/main/specification#hardening)

#### Requirement 1.3.1

> The `client` **MUST** provide methods for typed flag evaluation, including boolean, numeric, string, and structure, with parameters `flag key` (string, required), `default value` (boolean | number | string | structure, required), `evaluation context` (optional), and `evaluation options` (optional), which returns the flag value.

```typescript
// example boolean flag evaluation
boolean myBool =  client.getBooleanValue('bool-flag', false);

// example overloaded string flag evaluation with optional params
string myString = client.getStringValue('string-flag', 'N/A', evaluationContext, options);

// example number flag evaluation
number myNumber = client.getNumberValue('number-flag', 75);

// example overloaded structure flag evaluation with optional params
MyStruct myStruct = client.getObjectValue<MyStruct>('structured-flag', { text: 'N/A', percentage: 75 }, evaluationContext, options);
```

See [evaluation context](./03-evaluation-context.md) for details.

#### Condition 1.3.2

> The implementation language differentiates between floating-point numbers and integers.

##### Conditional Requirement 1.3.2.1

> The client **SHOULD** provide functions for floating-point numbers and integers, consistent with language idioms.

```java
int getIntValue(String flag, int defaultValue);

long getFloatValue(String flag, long defaultValue);
```

See [types](../types.md) for details.

#### Requirement 1.3.3

> The `client` **SHOULD** guarantee the returned value of any typed flag evaluation method is of the expected type. If the value returned by the underlying provider implementation does not match the expected type, it's to be considered abnormal execution, and the supplied `default value` should be returned.

### 1.4. Detailed Flag Evaluation

[![hardening](https://img.shields.io/static/v1?label=Status&message=hardening&color=yellow)](https://github.com/open-feature/spec/tree/main/specification#hardening)

#### Requirement 1.4.1

> The `client` **MUST** provide methods for detailed flag value evaluation with parameters `flag key` (string, required), `default value` (boolean | number | string | structure, required), `evaluation context` (optional), and `evaluation options` (optional), which returns an `evaluation details` structure.

```typescript
// example detailed boolean flag evaluation
FlagEvaluationDetails<boolean> myBoolDetails = client.getBooleanDetails('bool-flag', false);

// example detailed string flag evaluation
FlagEvaluationDetails<string> myStringDetails = client.getStringDetails('string-flag', 'N/A', evaluationContext, options);

// example detailed number flag evaluation
FlagEvaluationDetails<number> myNumberDetails = client.getNumberDetails('number-flag', 75);

// example detailed structure flag evaluation
FlagEvaluationDetails<MyStruct> myStructDetails = client.getObjectDetails<MyStruct>('structured-flag', { text: 'N/A', percentage: 75 }, evaluationContext, options);

```

#### Requirement 1.4.2

> The `evaluation details` structure's `value` field **MUST** contain the evaluated flag value.

#### Condition 1.4.3

> The language supports generics (or an equivalent feature).

##### Conditional Requirement 1.4.3.1

> The `evaluation details` structure **SHOULD** accept a generic argument (or use an equivalent language feature) which indicates the type of the wrapped `value` field.

#### Requirement 1.4.4

> The `evaluation details` structure's `flag key` field **MUST** contain the `flag key` argument passed to the detailed flag evaluation method.

#### Requirement 1.4.5

> In cases of normal execution, the `evaluation details` structure's `variant` field **MUST** contain the value of the `variant` field in the `flag resolution` structure returned by the configured `provider`, if the field is set.

#### Requirement 1.4.6

> In cases of normal execution, the `evaluation details` structure's `reason` field **MUST** contain the value of the `reason` field in the `flag resolution` structure returned by the configured `provider`, if the field is set.

#### Requirement 1.4.7

> In cases of abnormal execution, the `evaluation details` structure's `error code` field **MUST** contain an `error code`.

See [error code](../types.md#error-code) for details.

#### Requirement 1.4.8

> In cases of abnormal execution (network failure, unhandled error, etc) the `reason` field in the `evaluation details` **SHOULD** indicate an error.

#### Requirement 1.4.9

> Methods, functions, or operations on the client **MUST NOT** throw exceptions, or otherwise abnormally terminate. Flag evaluation calls must always return the `default value` in the event of abnormal execution. Exceptions include functions or methods for the purposes for configuration or setup.

Configuration code includes code to set the provider, instantiate providers, and configure the global API object.

#### Requirement 1.4.10

> In the case of abnormal execution, the client **SHOULD** log an informative error message.

Implementations may define a standard logging interface that can be supplied as an optional argument to the client creation function, which may wrap standard logging functionality of the implementation language.

#### Requirement 1.4.11

> The `client` **SHOULD** provide asynchronous or non-blocking mechanisms for flag evaluation.

It's recommended to provide non-blocking mechanisms for flag evaluation, particularly in languages or environments wherein there's a single thread of execution.

#### Requirement 1.4.12

> In cases of abnormal execution, the `evaluation details` structure's `error message` field **MAY** contain a string containing additional details about the nature of the error.

#### Requirement 1.4.13

> If the `flag metadata` field in the `flag resolution` structure returned by the configured `provider` is set, the `evaluation details` structure's `flag metadata` field **MUST** contain that value. Otherwise, it **MUST** contain an empty record.

This `flag metadata` field is intended as a mechanism for providers to surface additional information about a feature flag (or its evaluation) beyond what is defined within the OpenFeature spec itself. The primary consumer of this information is a provider-specific hook.

#### Condition 1.4.14

> The implementation language supports a mechanism for marking data as immutable.

##### Conditional Requirement 1.4.14.1

> Condition: `Flag metadata` **MUST** be immutable.

### Evaluation Options

#### Requirement 1.5.1

> The `evaluation options` structure's `hooks` field denotes an ordered collection of hooks that the client **MUST** execute for the respective flag evaluation, in addition to those already configured.

See [hooks](./04-hooks.md) for details.

### 1.6. Shutdown

[![experimental](https://img.shields.io/static/v1?label=Status&message=experimental&color=orange)](https://github.com/open-feature/spec/tree/main/specification#experimental)

#### Requirement 1.6.1

> The API **MUST** define a `shutdown` function, which, when called, must call the respective `shutdown` function on the active provider.

The precise name of this function is not prescribed by this specification.
Relevant language idioms should be considered when choosing the name for this function, in accordance with the resource-disposal semantics of the language in question.

see: [`shutdown`](./02-providers.md#25-shutdown)
