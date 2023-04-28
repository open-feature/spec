---
title: Events
description: Specification defining event semantics
toc_max_heading_level: 4
---

# 5. Events

[![experimental](https://img.shields.io/static/v1?label=Status&message=experimental&color=orange)](https://github.com/open-feature/spec/tree/main/specification#experimental)

## Overview

`Events` allow consumers (_application integrator_, _application author_, _integration author_) to react to state changes in the provider or underlying flag management system, such as flag definition changes, provider readiness, or error conditions. A provider may emit events or run a callback indicating that it received a certain event, optionally providing data associated with that event. Handlers registered on the client are then invoked with this data.

### 5.1. Provider events

#### Requirement 5.1.1

> The `provider` **MAY** define a mechanism for signalling the occurrence of one of a set of events, including `PROVIDER_READY`, `PROVIDER_ERROR`, `PROVIDER_CONFIGURATION_CHANGED` and `PROVIDER_STALE`, with an `event metadata` payload. 

If available, native event-emitter or observable/observer language constructs can be used.

see: [provider event types](../types.md#provider-events), [`event metadata`](../types.md#event-metadata).

#### Requirement 5.1.2

> When the `provider` signals the occurrence of a particular `event`, the associated `client` `event handlers` **MUST** run. 

If available, native event-emitter or observable/observer language constructs can be used.

see: [provider event types](./../types.md#provider-events) and [event handlers](#52-event-handlers).

#### Requirement 5.2.3

> `PROVIDER_ERROR` events **SHOULD** populate the `error event metadata`'s `error message` field.

The error message field should contain an informative message as to the nature of the error.

See [event metadata](../types.md#error-event-metadata)

### 5.2. Event handlers

#### Requirement 5.2.1

> The `client` **MUST** provide an `addHandler` function for attaching callbacks to `provider events`, which accepts event type(s) and a `event handler function`.

```java
  // run the myOnReadyHandler function when the PROVIDER_READY event is fired
  client.addHandler(ProviderEvents.Ready, MyClass::myOnReadyHandler);
```

see: [provider events](#51-provider-events)

#### Requirement 5.2.2

> The `event handler` function **MAY** accept a `event metadata` or `error event metadata` parameter.

see: [`event metadata`](../types.md#event-metadata), [`error event metadata`](../types.md#error-event-metadata)

#### Requirement 5.2.3

> If the provider's `initialize` function terminates normally, `PROVIDER_READY` handlers **MUST** run.

See [provider initialization](./02-providers.md#24-initialization) and [setting a provider](./01-flag-evaluation.md#setting-a-provider).

#### Requirement 5.2.4

> If the provider's `initialize` function terminates abnormally, `PROVIDER_ERROR` handlers **MUST** run.

See [provider initialization](./02-providers.md#24-initialization) and [setting a provider](./01-flag-evaluation.md#setting-a-provider).

#### Requirement 5.2.5

> `PROVIDER_READY` handlers added after the provider is already in a ready state **MUST** run immediately.

See [provider initialization](./02-providers.md#24-initialization) and [setting a provider](./01-flag-evaluation.md#setting-a-provider).

#### Requirement 5.2.6

> Event handlers **MUST** persist across `provider` changes.

Behavior of event handlers should be independent of the order of handler addition and provider configuration.