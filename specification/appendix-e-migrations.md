---
id: appendix-e
title: "Appendix E: Migrations"
description: Migration guidance for breaking spec changes
sidebar_position: 6
---

# Appendix E: Migrations

This appendix provides non-normative guidance for provider authors and SDK authors on migrating to new or changed specification requirements.

## Provider Lifecycle Event Emission

### Background

Prior to `v0.9.0`, the SDK emitted synthetic lifecycle events (`PROVIDER_READY`, `PROVIDER_ERROR`) on behalf of providers after lifecycle methods (`initialize`, `shutdown`, `on context changed`) returned.
This created a race condition in multi-threaded SDKs: the provider could emit events from background threads concurrently with SDK-emitted synthetic events, resulting in incorrect event ordering and inconsistent status.

The spec now requires providers to emit their own lifecycle events.
The SDK derives provider status entirely from the provider's event stream (see [provider status](./sections/02-providers.md#28-provider-status), [requirement 5.3.5](./sections/05-events.md#requirement-535)).

### For provider authors

Providers must now emit events for all state transitions, including those resulting from lifecycle methods:

- `PROVIDER_READY` after successful initialization
- `PROVIDER_ERROR` after failed initialization (with appropriate error code)
- `PROVIDER_RECONCILING` when beginning context reconciliation (static-context paradigm)
- `PROVIDER_CONTEXT_CHANGED` after successful context reconciliation (static-context paradigm)
- `PROVIDER_ERROR` after failed context reconciliation (static-context paradigm)

To signal to the SDK that your provider emits its own lifecycle events, implement the opt-in marker defined by the SDK (e.g. an interface, boolean property, or type-level tag).

Providers that do not implement this marker will continue to work via the SDK's legacy compatibility path (see below).

### For SDK authors

SDKs must detect whether a provider emits its own lifecycle events, via an opt-in marker (e.g. an interface, boolean property, or type-level tag).

- **Marker present:** the SDK does not emit synthetic lifecycle events. It derives status solely from the provider's event stream.
- **Marker absent (legacy):** the SDK emits synthetic lifecycle events after lifecycle methods return, as before. This path is deprecated.

The legacy path should be deprecated in the release that introduces the marker, with removal targeted for the next major version.
SDK authors should update any first-party providers and provider base classes to emit their own lifecycle events.
