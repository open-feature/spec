# Hooks

## Overview

Hooks are a mechanism whereby application developers can add arbitrary behavior
to flag evaluation. They operate similarly to middleware in many web frameworks.

### Definitions

**Stage**: An explicit portion of the flag evaluation lifecycle. e.g. `before` being "before the evaluation is run.
**Invocation**: A single call to evaluate a flag. `client.getBooleanValue(..)` is an invocation.
**API**: The global API singleton.

### Hook context

Hook context exists to provide hooks with information about the invocation.

> Hook context **MUST** provide: the flag key, evaluation context, default value and a list of  executed hooks by stage.

> Condition: You **MUST** provide `flag type` if the language type system differentiates between strings, numbers, booleans, and structures.

> Hook context **SHOULD** provide: provider, client

> flag key, flag type, default value properties **MUST** be immutable.

> The evaluation context **MUST** be mutable only within the `before` hook.

### State

> State **MUST** be a map of objects.

> Condition: State **MUST** be immutable, if the implementation language supports a mechanism for marking data as immutable.

### Hook creation and parameters

> Hooks **MUST** specify at least one stage.

> The `before` stage *MUST* run before flag evaluation occurs. It accepts a `hook context` (required) and `state` (optional) as parameters and returns either a `HookContext` or nothing.

```
HookContext|void before(HookContext, State)
```

> The `after` stage **MUST** run after flag evaluation occurs. It accepts a `hook context` (required), `flag evaluation details` (required) and `state` (optional). It has no return value.

> The `error` hook runs when errors are encountered in the `before` or `after` state or when flag evaluation errors. It accepts `hook context` (required), `exception` for what went wrong (required), and `state` (optional). It has no return value.

> The `finally` hook **MUST** run after the `before`, `after`, and `error` stages. It accepts a `hook context` (required) and `state` (optional). There is no return value.

> Condition: If `finally` is a reserved word in the language, `afterAll` should be used.

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

> Hooks **MUST** be evaluated in the following order: API before, client before, invocation before, invocation after, client after, API after, invocation finally, client finally, API finally. If errors are present, the order is: invocation error, client error, API error.

```
// here we are using the order defined above (note if it wasn't defined, we'd have to order them somehow anyway
Hooks[] allHooks = [ ...OpenFeature.getHooks(), ...this.getHooks(), ...evaluationOptions.hooks ]

try {
  // evaluation all our before hooks
  for (h in allHooks) {
    h.before(...);
  }

  provider.resolveValue(...);

  // evaluation all our after hooks
  for (h in allHooks.reverse()) {
    h.after(...);
  }
} catch (Error err) {
  // evaluation all our error hooks
  for (h in allHooks.reverse()) {
    h.error(...);
  }
} finally {
  // evaluation all our finally hooks
  for (h in allHooks.reverse()) {
    h.finally(...);
  }
}
```

> When an error occurs in hook evaluation, further evaluation **MUST** stop and error hook evaluation begins.

> If an error is encountered in the error stage, it **MUST** not be returned to the user.

> If an error occurs in the `before` or `after` hooks, the `error` hooks **MUST** be invoked.

> If an error occurs in the `finally` hook, it **MUST** not trigger the `error` hook.

### [Flag evaluation options](../types.md#evaluation-options)

> `Flag evalution options` must contain a list of hooks to evaluate.

> `Flag evaluation options` may contain `state`, a map of data to be provided to hook invocations.

> `state` **MUST** be passed to each hook through a parameter. It is merged into the object in the precedence order API -> Client -> Invocation (last wins).

```python
state = {}
for source in [API, Client, Invocation]:
  for key, value in source:
    state[key] = value
```

> The hook **MUST** not alter the `state` object.

### Hook evaluation

> `state` **MUST** passed between each hook.
