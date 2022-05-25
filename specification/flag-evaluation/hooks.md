# Hooks

## Overview

Hooks are a mechanism whereby application developers can add arbitrary behavior
to flag evaluation. They operate similarly to middleware in many web frameworks.

### Definitions

**Hook**: Application author/integrator-supplied logic that is called by the OpenFeature framework at a specific stage.
**Stage**: An explicit portion of the flag evaluation lifecycle. e.g. `before` being "before the evaluation is run.
**Invocation**: A single call to evaluate a flag. `client.getBooleanValue(..)` is an invocation.
**API**: The global API singleton.

### Hook context

Hook context exists to provide hooks with information about the invocation.

###### Requirement 1.1

> Hook context **MUST** provide: the flag key, flag type, evaluation context, and the default value.


##### Requirement 1.2

> Hook context **SHOULD** provide: provider (instance) and client (instance)

##### Requirement 1.3

> flag key, flag type, default value properties **MUST** be immutable. If the language does not support immutability, the hook **MUST NOT** modify these properties.

##### Requirement 1.4

> The evaluation context **MUST** be mutable only within the `before` hook.

### HookHints

##### Requirement 2.1

> HookHints **MUST** be a map of objects.


##### Condition 2.2

> The implementation language supports a mechanism for marking data as immutable.
>
> ##### 2.2.1
>
> Condition: HookHints **MUST** be immutable.


### Hook creation and parameters


##### Requirement 3.1

> Hooks **MUST** specify at least one stage.

##### Requirement 3.2

> The `before` stage **MUST** run before flag evaluation occurs. It accepts a `hook context` (required) and `HookHints` (optional) as parameters and returns either an `EvaluationContext` or nothing.

```
EvaluationContext|void before(HookContext, HookHints)
```

##### Requirement 3.3

> Any `EvaluationContext` returned from a `before` hook **MUST** be passed to subsequent `before` hooks (via `HookContext`).

##### Requirement 3.4

> When `before` hooks have finished executing, any resulting `EvaluationContext` **MUST** be merged with the invocation `EvaluationContext` with the invocation `EvaluationContext` taking precedence in the case of any conflicts.

##### Requirement 3.5

> The `after` stage **MUST** run after flag evaluation occurs. It accepts a `hook context` (required), `flag evaluation details` (required) and `HookHints` (optional). It has no return value.

##### Requirement 3.6

> The `error` hook **MUST** run when errors are encountered in the `before` stage, the `after` stage or during flag evaluation. It accepts `hook context` (required), `exception` for what went wrong (required), and `HookHints` (optional). It has no return value.

##### Requirement 3.7

> The `finally` hook **MUST** run after the `before`, `after`, and `error` stages. It accepts a `hook context` (required) and `HookHints` (optional). There is no return value.

##### Condition 3.8

> `finally` is a reserved word in the language.
>
> ##### 3.8.1
>
> Condition: If `finally` is a reserved word in the language, `finallyAfter` **SHOULD** be used.

### Hook registration & ordering

##### Requirement 4.1

> The API, Client and invocation **MUST** have a method for registering hooks which accepts `flag evaluation options`

```js
OpenFeature.addHooks(new Hook1());

//...

Client client = OpenFeature.getClient();
client.addHooks(new Hook2());
`
//...

client.getValue('my-flag', 'defaultValue', new Hook3());
```

##### Requirement 4.2

> Hooks **MUST** be evaluated in the following order:
> - before: API, Client, Invocation
> - after: Invocation, Client, API
> - error (if applicable): Invocation, Client, API
> - finally: Invocation, Client, API

##### Requirement 4.3

> If an error occurs in the `finally` hook, it **MUST NOT** trigger the `error` hook.

In practice, this means that errors that occur in the finally hook will bubble up.

##### Requirement 4.4

> If an error occurs in the `before` or `after` hooks, the `error` hooks **MUST** be invoked.

##### Requirement 4.5

> If an error occurs during the evaluation of `before` or `after` hooks, any remaining hooks in the `before` or `after` stages **MUST NOT** be invoked.

##### Requirement 4.6

> If an error is encountered in the error stage, it **MUST NOT** be returned to the user.


### [Flag evaluation options](../types.md#evaluation-options)

Usage might looks something like:

```python
val = client.get_boolean_value('my-key', False, evaluation_options={
    'hooks': new MyHook(),
    'hook_hints': {'side-item': 'onion rings'}
})
```

##### Requirement 5.1

> `Flag evalution options` **MUST** contain a list of hooks to evaluate.

##### Requirement 5.2

> `Flag evaluation options` **MAY** contain `HookHints`, a map of data to be provided to hook invocations.

##### Requirement 5.3

> `HookHints` **MUST** be passed to each hook.

##### Requirement 5.4

> The hook **MUST NOT** alter the `HookHints` object.
