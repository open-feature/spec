# Flag Evaluation API

**Status**: [Experimental](../README.md#document-statuses)

## Overview

The `evaluation API` allows for the evaluation of feature flag values, independent of any flag control plane or vendor. In the absence of a [provider](../provider/providers.md) the `evaluation API` uses the "No-op provider", which simply returns the supplied default flag value.

### API Initialization and Configuration

##### Requirement 1.1

> The `API`, and any state it maintains **SHOULD** exist as a global singleton, even in cases wherein multiple versions of the `API` are present at runtime.

It's important that multiple instances of the `API` not be active, so that state stored therein, such as the registered `provider`, static global `evaluation context`, and globally configured `hooks` allow the `API` to behave predictably. This can be difficult in some runtimes or languages, but implementors should make their best effort to ensure that only a single instance of the `API` is used.

##### Requirement 1.2

> The `API` **MUST** provide a function to set the global `provider` singleton, which accepts an API-conformant `provider` implementation.

```
// example provider mutator
OpenFeature.setProvider(new MyProvider());
```

See [provider](../provider//providers.md) for details.

##### Requirement 1.3

> The `API` **MUST** provide a function to add `hooks` which accepts one or more API-conformant `hooks`, and appends them to the collection of any previously added hooks. When new hooks are added, previously added hooks are not removed.

```
// example hook attachment
OpenFeature.addHooks([new MyHook()]);
```

See [hooks](./hooks.md) for details.

##### Requirement 1.4

> The API **MUST** provide a function for retrieving the `provider` implementation.

```
// example provider accessor
OpenFeature.getProvider();
```

See [provider](../provider/provider.md) for details.

##### Requirement 1.5

> The `API` **MUST** provide a function for creating a `client` which accepts the following options:
>
> - name (optional): A logical string identifier for the client.

```
// example client creation and retrieval
OpenFeature.getClient({
  name: 'my-openfeature-client'
});
```

The name is a logical identifier for the client.

### Client Usage

##### Requirement 1.6

> The client **MUST** provide a method to add `hooks` which accepts one or more API-conformant `hooks`, and appends them to the collection of any previously added hooks. When new hooks are added, previously added hooks are not removed.

```
// example hook attachment
client.addHooks([new MyHook()]);
```

See [hooks](./hooks.md) for details.

#### Flag Evaluation

##### Requirement 1.7

> The `client` **MUST** provide methods for flag evaluation, with parameters `flag key` (string, required), `default value` (boolean | number | string | structure, required), `evaluation context` (optional), and `evaluation options` (optional), which returns the flag value.

```
// example flag evaluation
var myValue = client.getValue('my-flag', false);
```

##### Condition 1.8

> The language type system differentiates between strings, numbers, booleans and structures.
>
> ##### Conditional Requirement 1.8.1
>
> > The `client` **MUST** provide methods for typed flag evaluation, including boolean, numeric, string, and structure.

```
// example boolean flag evaluation
boolean myBool =  client.getBooleanValue('bool-flag', false);

// example overloaded string flag evaluation with optional params
string myString = client.getStringValue('string-flag', 'N/A', evaluationContext, options);

// example number flag evaluation
number myNumber = client.getNumberValue('number-flag', 75);

// example overloaded structure flag evaluation with optional params
MyStruct myStruct = client.getObjectValue<MyStruct>('structured-flag', { text: 'N/A', percentage: 75 }, evaluationContext, options);
```

> > See [evaluation context](../evaluation-context/evaluation-context.md) for details.
>
> ##### Conditional Requirement 1.8.2
>
> > The `client` **SHOULD** guarantee the returned value of any typed flag evaluation method is of the expected type. If the value returned by the underlying provider implementation does not match the expected type, it's to be considered abnormal execution, and the supplied `default value` should be returned.

#### Detailed Flag Evaluation

##### Requirement 1.9

> The `client` **MUST** provide methods for detailed flag value evaluation with parameters `flag key` (string, required), `default value` (boolean | number | string | structure, required), `evaluation context` (optional), and `evaluation options` (optional), which returns an `evaluation details` structure.

```
// example detailed boolean flag evaluation
FlagEvaluationDetails<boolean> myBoolDetails = client.getBooleanDetails('bool-flag', false);

// example detailed string flag evaluation
FlagEvaluationDetails<string> myStringDetails = client.getStringDetails('string-flag', 'N/A', evaluationContext, options);

// example detailed number flag evaluation
FlagEvaluationDetails<number> myNumberDetails = client.getNumberDetails('number-flag', 75);

// example detailed structure flag evaluation
FlagEvaluationDetails<MyStruct> myStructDetails = client.getObjectDetails<MyStruct>('structured-flag', { text: 'N/A', percentage: 75 }, evaluationContext, options);

```

##### Requirement 1.10

> The `evaluation details` structure's `value` field **MUST** contain the evaluated flag value.

##### Condition 1.11

> The language supports generics (or an equivalent feature).
>
> ##### Conditional Requirement 1.11.1
>
> > The `evaluation details` structure **SHOULD** accept a generic argument (or use an equivalent language feature) which indicates the type of the wrapped `value` field.

##### Requirement 1.12

> The `evaluation details` structure's `flag key` field **MUST** contain the `flag key` argument passed to the detailed flag evaluation method.

##### Requirement 1.13

> In cases of normal execution, the `evaluation details` structure's `variant` field **MUST** contain the value of the `variant` field in the `flag resolution` structure returned by the configured `provider`, if the field is set.

##### Requirement 1.14

> In cases of normal execution, the `evaluation details` structure's `reason` field **MUST** contain the value of the `reason` field in the `flag resolution` structure returned by the configured `provider`, if the field is set.

##### Requirement 1.15

> In cases of abnormal execution, the `evaluation details` structure's `error code` field **MUST** identify an error occurred during flag evaluation, having possible values `"PROVIDER_NOT_READY"`, `"FLAG_NOT_FOUND"`, `"PARSE_ERROR"`, `"TYPE_MISMATCH"`, or `"GENERAL"`.

##### Requirement 1.16

> In cases of abnormal execution (network failure, unhandled error, etc) the `reason` field in the `evaluation details` **SHOULD** indicate an error.

##### Requirement 1.17

> The `evaluation options` structure's `hooks` field denotes a collection of hooks that the client **MUST** execute for the respective flag evaluation, in addition to those already configured.

See [hooks](./hooks.md) for details.

##### Requirement 1.18

> Methods, functions, or operations on the client **MUST NOT** throw exceptions, or otherwise abnormally terminate. Flag evaluation calls must always return the `default value` in the event of abnormal execution. Exceptions include functions or methods for the purposes for configuration or setup.

##### Requirement 1.19

> In the case of abnormal execution, the client **SHOULD** log an informative error message.

Implementations may define a standard logging interface that can be supplied as an optional argument to the client creation function, which may wrap standard logging functionality of the implementation language.

##### Requirement 1.20

> The `client` **SHOULD** provide asynchronous or non-blocking mechanisms for flag evaluation.

It's recommended to provide non-blocking mechanisms for flag evaluation, particularly in languages or environments wherein there's a single thread of execution.

##### Requirement 1.21

> The `client` **MUST** transform the `evaluation context` using the `provider's` `context transformer` function, before passing the result of the transformation to the provider's flag resolution functions.

See [context transformation](../provider/providers.md#context-transformation) for details.
