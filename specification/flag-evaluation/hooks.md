# Hooks

## Overview

Hooks are a mechanism which can tie into the lifecycle of flag evaluation. They
operate similarly to middleware in many web frameworks.

### Hook context

Hook context exists to provide hooks with information about the invocation.

> Hook context **MUST** provide: the flag key, flag type, evaluation context, default value and a list of  executed hooks by stage.

> Hook context **SHOULD** provide: provider, client

> flag key, flag type, default value properties **MUST** be immutable.

> The evaluation context **MUST** be mutable only within the `before` hook.


### Hook creation and parameters

> Hooks **MUST** specify at least one stage: `before(HookContext, ImmutableState)`, `after(HookContext, FlagEvaluationDetails, , ImmutableState)`, `error(HookContext, Exception, ImmutableState)`, or `finally(HookContext, ImmutableState)`.

> Condition: If `finally` is a reserved word in the language, `afterAll` should be used.

### Hook registration & ordering

> The API, Client and invocation **MUST** have a method for registering hooks which accepts `flag evaluation options`

> Hooks **MUST** be evaluated in the following order: API before, client before, invocation before, invocation after, client after, API after, invocation finally, client finally, API finally. If errors are present, the order is: invocation error, client error, API error.

> When an error occurs in hook evaluation, further evaluation **MUST** stop and error hook evaluation begins.

> If an error is encountered in the error flow, it **MUST** not be returned to the user.

> If an error occurs in the `before` or `after` hooks, the `error` hooks **MUST** be invoked.

> If an error occurs in the `finally` hook, it **MUST** not trigger the `error` hook.

### Flag evaluation options

> `Flag evalution options` must contain a list of hooks to evaluate.

> `Flag evaluation options` may contain `immutable state`, a map of data to be provided to hook invocations.

> Immutable hook data **MUST** be passed to each hook through a parameter. It is merged into the object in the precedence order API -> Client -> Invocation.

> The hook **MUST** not alter the `immutable state` object.

### Hook evaluation

> `Immutable state` **MUST** passed between each hook.

> As hooks are run, they **MUST** be added to an `evaluatedHooks` property within the `EvaluationContext`.

> If a hook throws an error, it **MUST** be in `evaluatedHooks`.

> The `flag evaluation details`, if returned, **must** contain a list of `evaluated hooks`.
