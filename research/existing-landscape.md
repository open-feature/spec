
# Feature Flag Management - API/SDK Landscape Research

## Goal

The goal of this research is to document the APIs and SDKs of existing feature flag
management tools in order to identity patterns that should be considered when
defining the OpenFeature spec.

> NOTE: This research focuses primarily on the server-side NodeJS SDKs

## Unleash

Unleash has documented the expected behavior of the client SDKs [here](https://github.com/Unleash/client-specification).

```typescript
  // isEnabled(name: string, context?: Context, fallbackFunction?: FallbackFunction): boolean;
  // isEnabled(name: string, context?: Context, fallbackValue?: boolean): boolean;
  const featureEnabled = unleash.isEnabled("test-release");
```

### Context

Context in Unleash is used to make feature state evaluation at runtime. The noteworthy properties are:

- userId
- sessionId
- remoteAddress
- environment
- appName
- properties (additional context as key-value pairs)

The context interface for NodeJS can be found
[here](https://github.com/Unleash/unleash-client-node/blob/main/src/context.ts).

### Variant

Variants are extensions to feature flags in Unleash. They allow Unleash
administrators to define customized response payloads (which can be further
customized using context). For example, if a feature flag called 'banner-color'
is enabled, the variant could return a string value specifying which color the
banner should be, using, for instance, the user's role.

The variant interfaces for NodeJS can be found [here](https://github.com/Unleash/unleash-client-node/blob/main/src/variant.ts).


```typescript
  // getVariant(name: string, context?: Context, fallbackVariant?: Variant): Variant;
  const colorVariant = unleash.getVariant("banner-color");
  // NOTE: Values are always strings but can stringified JSON
  const color = colorVariant.enabled && colorVariant.payload?.value || "#0000FF";
```

### Flag evaluation

Unleash uses
[strategies](https://github.com/Unleash/unleash-client-node/blob/main/src/strategy/strategy.ts)
to do local flag evaluation in their server-side SDKs. A number of strategies come out of the box
and it's possible to create custom strategies that are registered in the client
constructor. Flag configurations are periodically polled and persisted in memory
by default.

> NOTE: Client-side SDKs require the [Unleash
> Proxy](https://github.com/Unleash/unleash-proxy), which handles flag
> evaluation on a server.
### Key findings

 - Evaluation logic is handled in the SDK and some clients support synchronous
   operations.
 - The fallback argument accepting a function provides developers the opportunity
   for more sophisticated logic when an error occurs.
 - Variants do not support integer values.
 - Some SDKs, like
   [Java](https://docs.getunleash.io/sdks/java_sdk#step-4-provide-unleash-context),
   request scoped context.
 - Initial synchronization can impact app start-up time.
 - Invalid flag IDs behave like a disabled feature.
 

## Flagsmith

The following is an example of a basic flag evaluation where the expected return
type is a boolean.

```typescript
  // hasFeature(key: string): Promise<boolean>;
  // hasFeature(key: string, userId: string): Promise<boolean>;
  const featureEnabled = await flagsmith.hasFeature("test-feature");
```

It's also possible to return values associated with a feature flag. These values
are returned despite the state of the flag.

```typescript
  // getValue(key: string): Promise<string | number | boolean>;
  // getValue(key: string, userId: string): Promise<string | number | boolean>;
  const value = await flagsmith.getValue("test-feature");
```

### Identity management

Users are automatically created the first time they're referenced in a flag
evaluation. Traits can be associated with a user and are persisted
server-side. It doesn't appear that traits can be removed via the SDK.

### Segments

Segments can be applied to a feature, allowing Flagsmith administrators to
override default behavior. This is done by evaluating traits associated with a
user.

### Flag evaluation

Flagsmith performs flag evaluation server-side and results can be cached if
desired. This service is written in Python and can be found
[here](https://github.com/Flagsmith/flagsmith-engine).

### Key findings

 - Evaluation logic is handed on the server and called via REST. However, the v2
   SDK allows developers to choose between remote or local evaluation. The
   pro/cons list can be found
   [here](https://docs.flagsmith.com/next/clients/overview#pros-cons-and-caveats).
 - Identities need to maintained outside of the flag evaluation.
 - Values are always returned, even if the flag is disabled.
 - Invalid flag IDs behave like a disabled feature and return a null value (In
   NodeJS).

## LaunchDarkly

The method names and signatures vary between languages. The following is how a
flag is evaluated in NodeJS:

```typescript
  /**
   * variation(
   *   key: string,
   *   user: LDUser,
   *   defaultValue: LDFlagValue,
   *   callback?: (err: any, res: LDFlagValue) => void
   * ): Promise<LDFlagValue>;
   */
  const value = await ld.variation("test-feature", { key: "test-user" }, false);
```

And this is that same flag in Java:

```java
  /*
  Other methods include intVariation, doubleVariation, stringVariation, and jsonValueVariation
  */
  boolean value = client.boolVariation("test-feature", user, false);
```

## Users

A user key always needs to be defined when performing a flag evaluation.
Anonymous users still need a key and should have the property `anonymous` set to
true. More information can be found
[here](https://docs.launchdarkly.com/sdk/features/user-config).

The user interface accepts the following properties:
 - key
 - secondary
 - name
 - firstName
 - lastName
 - email
 - avatar
 - ip
 - country
 - anonymous
 - custom

The user interface for NodeJS can be found
[here](https://github.com/launchdarkly/node-server-sdk/blob/master/index.d.ts#L533).

### Flag evaluation

LaunchDarkly performs local flag evaluation in both the client and server
SDKs. Configuration updates can be streamed using Server Sent Events (SSE) or by
polling and persisted in memory by default.

> NOTE: Client-side SDKs do not subscribe to real-time updates until the
> `.on('change')` method is called.
### Key findings
 - There's a `variationDetails` method that returns evaluation and error details.
 - Remote debugging option captures additional evaluation details.
 - The return type from the variation method is `any` (In NodeJS).
 - Flag variation is defined during flag creation and cannot be modified later.
 - Private user attributes can be [disabled from
   analytics](https://docs.launchdarkly.com/home/users/attributes#configuring-private-attribute-settings-in-your-sdk)
   while still being available for local flag evaluation.
 - It's possible to update the `processor` used by the client to [read from a
   file](https://docs.launchdarkly.com/sdk/features/flags-from-files).

## Split

The following is an example of a basic flag evaluation. Split refers to the
response type as a treatment and it's always a string.

```typescript
  // getTreatment(splitName: string, attributes?: Attributes): Treatment
  // getTreatment(key: SplitKey, splitName: string, attributes?: Attributes): Treatment
  const treatment = client.getTreatment("test-user", "test-feature");

  // Custom attributes can also be used during treatment evaluation
  const treatmentUsingAttributes = client.getTreatment("test-user", "test-feature", { groups: ["internal"] });
```

It's also possible to attach a configuration to a treatment. This can be either
a key/value pair or JSON. The following example shows how you can access the
config associated with a treatment.

```typescript
  // getTreatmentWithConfig(splitName: string, attributes?: Attributes): TreatmentWithConfig
  // getTreatmentWithConfig(key: SplitKey, splitName: string, attributes?: Attributes): TreatmentWithConfig
  const treatmentWithConfig = client.getTreatmentWithConfig("test-user", "test-feature");
  // Treatment value
  console.log(treatmentWithConfig.treatment);
  // Config is either a string or null
  console.log(treatmentWithConfig.config)
```

### Treatments

Treatment values are the primary response when performing a flag evaluation.
These values are always strings and default to `on` and `off`. However, it's
possible to create a up to 20 treatments per split (feature flag) and the
default values can be changed.

There are also [reserved words](https://help.split.io/hc/en-us/articles/360020525112-Edit-treatments#about-reserved-words) that can't be used on a treatment.
### Attributes

Attributes can be used to build targeting rules for feature flags. They are maps
that are passed into the `getTreatment` method. Supported values are: strings,
numbers, dates, booleans, and sets.

### Flag evaluation

Split performs local flag evaluation in both the client and server
SDKs. Configuration updates can be streamed using Server Sent Events (SSE) or by
polling and persisted in memory by default. A
[proxy](https://help.split.io/hc/en-us/articles/4415960499213-Split-Proxy) can
be used to reduce the connection latency and number of connections directly
accessing Split.

It's also possible to use a [Split
Evaluator](https://help.split.io/hc/en-us/articles/360020037072-Split-Evaluator)
for languages without an official SDK. This exposes a REST API using the NodeJS SDK behind the
scenes.

### Key findings

 - SDKs support a [localhost
   mode](https://help.split.io/hc/en-us/articles/360020564931-Node-js-SDK#localhost-mode).
 - Treatment return values are string, so string a comparison is used to
   determine the state of the flag.
 - Additional metrics can be collected by sending events via the `track` method.
 - Traffic splitting is deterministic based on a hash of the user id.
 - When a visitor is assigned a treatment for a split, an impression is
   created. Registering a `logImpression` callback provides a detailed overview
   of the impression, attributes, and available metadata.
 - A
   [manager](https://help.split.io/hc/en-us/articles/360020564931-Node-js-SDK#manager)
   can be created with the same factory used to create the client. The manager
   contains methods that can be used to understand what flags exist and how they're
   configured.
