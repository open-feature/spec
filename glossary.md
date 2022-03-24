# Glossary

This document defines some terms that are used across this specification.

<details>
<summary>Table of Contents</summary>

<!-- toc -->

- [User Roles](#user-roles)
  * [Application Author](#application-author)
  * [Provider Author](#provider-author)
  * [Integration Author](#integration-author)
  * [Library Author](#library-author)
- [Common](#common)
  * [Feature Flag API](#feature-flag-api)
  * [Feature Flag SDK](#feature-flag-sdk)
  * [Provider](#provider)
  * [Integration](#integration)
  * [Context](#context)

<!-- tocstop -->

</details>

## User Roles

### Application Author

The maintainer of an an application or service which utilizes the feature flags API to manage functionality.

### Provider Author

The maintainer of an SDK-compliant provider which implements the necessary interfaces required for flag evaluation.

### Integration Author

The maintainer of an SDK-compliant integration which implements additional secondary functionality besides flag evaluation.

### Library Author

The maintainer of a shared library which is a dependency of many applications or libraries, which utilizes the feature flags API to allow consumers to manage library functionality.

## Common

### Feature Flag API

The interfaces and abstractions used by Application Author to implement feature flags in their application or service.

### Feature Flag SDK

The interfaces and abstractions used by Provider Authors and Integration Authors to add support for their feature flag implementation or integration.

### Provider

An SDK-compliant feature flag implementation that is abstracted by the Feature Flag API. Implementations may include popular Saas feature flag vendors, custom "in-house" feature flag infrastructure, or open-source implementations.

### Integration

An SDK-compliant secondary function that is abstracted by the Feature Flag API, and requires only minimal configuration by the Application Author. Examples include telemetry, tracking, custom logging and monitoring.

### Context

The flag evaluation context, which contains information about the runtime environment, details of the transport method encapsulating the flag evaluation, the host, the client, the subject (user), etc.