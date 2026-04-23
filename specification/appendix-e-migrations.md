---
id: appendix-e
title: "Appendix E: Migrations"
description: SDK migration guidance for breaking spec changes
sidebar_position: 6
---

# Appendix E: Migrations

This appendix provides non-normative guidance for SDK authors on migrating to new or changed specification requirements without breaking existing providers or application consumers.

## Provider Status Ownership

### Background

Prior to this change, provider status (e.g. `NOT_READY`, `READY`, `ERROR`) was managed by the SDK on behalf of the provider. The SDK would set status and emit events after lifecycle methods (`initialize`, `shutdown`, `on context change`) returned. This created a race condition in multi-threaded SDKs: the provider could change its own state (e.g. emit an error event from a background thread) in the window between the lifecycle method returning and the SDK writing its post-lifecycle status and emitting the corresponding event. The result was incorrect event ordering and inconsistent status.

The spec now requires providers to own their status and emit events atomically with status transitions (see [provider status](./sections/02-providers.md#28-provider-status)).

### Migration: the `StateManagingProvider` interface

To avoid breaking existing providers, SDKs should introduce an opt-in interface (or equivalent mechanism) that new providers implement to signal they manage their own status. Existing providers that do not implement this interface continue to have their status managed by the SDK, preserving backwards compatibility. This legacy behavior is deprecated and should be removed in the next major version.

The interface should expose:

- A `status` accessor that returns the provider's current status
- A discriminant or marker (e.g. an additional interface, a boolean property, or a type-level tag) that allows the SDK to detect at registration time whether the provider manages its own state

### SDK wrapper behavior

SDKs typically wrap registered providers in an internal adapter (e.g. a "provider wrapper" or "state manager") that mediates lifecycle calls and event forwarding. The wrapper should branch based on whether the registered provider implements the state-managing interface.

```mermaid
flowchart TD
    A[Provider registered with SDK] --> B{Implements state-managing interface?}

    B -- Yes --> C[SDK wrapper delegates status to provider]
    C --> C1[initialize / shutdown / onContextChange: SDK skips state writes AND event emissions]
    C --> C2[Provider events: SDK skips state writes]
    C --> C3[status: reads from provider directly]

    B -- No --> D[SDK wrapper manages state internally - legacy, deprecated]
    D --> D1[initialize / shutdown / onContextChange: SDK sets state AND emits events after return]
    D --> D2[Provider events: SDK updates state on emit]
    D --> D3[status: reads from SDK wrapper]

    C1 --> E[Provider-emitted events still propagate to registered handlers]
    C2 --> E
    C3 --> E
    D1 --> E
    D2 --> E
    D3 --> E
```

### What the SDK skips for state-managing providers

For providers that implement the state-managing interface, the SDK must not perform any of the following actions that it would normally perform for legacy providers:

- Setting status to `READY` after `initialize()` succeeds
- Setting status to `ERROR` or `FATAL` after `initialize()` fails
- Setting status to `NOT_READY` after `shutdown()` completes
- Emitting `PROVIDER_READY` or `PROVIDER_ERROR` events after `initialize()`
- Updating status when the provider emits events at runtime (the provider already set its own status atomically with the event)
- (Static-context paradigm only) Setting `RECONCILING` status, emitting `PROVIDER_RECONCILING`, setting `READY`/`ERROR` status, or emitting `PROVIDER_CONTEXT_CHANGED`/`PROVIDER_ERROR` during `on context change` handling

### What the SDK still does for all providers

Regardless of whether the provider manages its own state, the SDK continues to:

- Call `initialize()`, `shutdown()`, and `on context change` lifecycle methods on the provider
- Forward provider-emitted events to registered domain and API-level event handlers
- Run late-attached handlers immediately if the provider is already in the associated state
- Enforce short-circuit behavior for `NOT_READY` and `FATAL` statuses during flag evaluation

### Deprecation

The legacy path (SDK-managed status) should be deprecated in the release that introduces the state-managing interface, with removal targeted for the next major version. SDK authors should update any first-party providers and provider base classes to implement the new interface.
