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

> Hook context **MUST** provide: the flag key, evaluation context, default value and a list of  executed hooks by stage.

> Condition: You **MUST** provide `flag type` if the language type system differentiates between strings, numbers, booleans, and structures.

> Hook context **SHOULD** provide: provider, client

> flag key, flag type, default value properties **MUST** be immutable. If the language does not support immutability, the hook **MUST** not modify these properties.

> The evaluation context **MUST** be mutable only within the `before` hook.

### HookHints

> HookHints **MUST** be a map of objects.

> Condition: HookHints **MUST** be immutable, if the implementation language supports a mechanism for marking data as immutable.

### Hook creation and parameters

> Hooks **MUST** specify at least one stage.

> The `before` stage *MUST* run before flag evaluation occurs. It accepts a `hook context` (required) and `state` (optional) as parameters and returns either a `HookContext` or nothing.

```
HookContext|void before(HookContext, HookHints)
```

> The `after` stage **MUST** run after flag evaluation occurs. It accepts a `hook context` (required), `flag evaluation details` (required) and `HookHints` (optional). It has no return value.

> The `error` hook runs when errors are encountered in the `before` or `after` stage or when flag evaluation errors. It accepts `hook context` (required), `exception` for what went wrong (required), and `HookHints` (optional). It has no return value.

> The `finally` hook **MUST** run after the `before`, `after`, and `error` stages. It accepts a `hook context` (required) and `HookHints` (optional). There is no return value.

> Condition: If `finally` is a reserved word in the language, `finallyAfter` should be used.

### Hook registration & ordering

> The API, Client and invocation **MUST** have a method for registering hooks which accepts `flag evaluation options`

```js
OpenFeature.addHooks(new Hook1());

//...

Client client = OpenFeature.getClient();
client.addHooks(new Hook2());

//...

client.getValue('my-flag', 'defaultValue', new Hook3());
```

> Hooks **MUST** be evaluated in the following order:
> - before: API, Client, Invocation
> - after: Invocation, Client, API
> - error (if applicable): Invocation, Client, API
> - finally: Invocation, Client, API> If an error occurs in the `finally` hook, it **MUST** not trigger the `error` hook.

> If an error occurs in the `before` or `after` hooks, the `error` hooks **MUST** be invoked.

> If an error occurs during the evaluation of `before` or `after` hooks, any remaining hooks in the `before` or `after` stages **MUST** not be invoked.

> If an error is encountered in the error stage, it **MUST** not be returned to the user.


### [Flag evaluation options](../types.md#evaluation-options)

Usage might looks something like:

```python
val = client.get_boolean_value('my-key', False, evaluation_options={
    'hooks': new MyHook(),
    'hook_hints': {'side-item': 'onion rings'}
})
```

> `Flag evalution options` must contain a list of hooks to evaluate.

> `Flag evaluation options` may contain `HookHints`, a map of data to be provided to hook invocations.

> `HookHints` **MUST** be passed to each hook through a parameter. It is merged into the object in the precedence order API -> Client -> Invocation (last wins).

```python
hook_hints = {}
for source in [API, Client, Invocation]:
  for key, value in source:
    hook-hints[key] = value
```

> The hook **MUST** not alter the `HookHints` object.

### Hook evaluation

> `HookHints` **MUST** passed between each hook.
