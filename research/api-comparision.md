# API Comparison

The goal of this research is to make it easy to quickly compare feature flag
vendor SDK API's in order to help define the OpenFeature spec.

## Flag Return Types

| Provider x supported types | Unleash            | Flagsmith          | LaunchDarkly       | Split              | CloudBees          | Harness            |
| -------------------------- | ------------------ | ------------------ | ------------------ | ------------------ | ------------------ | ------------------ |
| boolean                    | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |                    | :heavy_check_mark: | :heavy_check_mark: |
| string                     | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| numeric                    |                    |                    | :heavy_check_mark: |                    | :heavy_check_mark: | :heavy_check_mark: |
| JSON                       | :heavy_check_mark: |                    |                    | :heavy_check_mark: |                    | :heavy_check_mark: |

### Boolean

<details>
  <summary>Java</summary>

```java
/**
* Unleash
*
* SDK Repo: https://github.com/Unleash/unleash-client-java
*/
boolean isEnabled(String toggleName)
boolean isEnabled(String toggleName, UnleashContext context)
boolean isEnabled(String toggleName, UnleashContext context, boolean defaultSetting)
boolean isEnabled(String toggleName, BiFunction<String, UnleashContext, Boolean> fallbackAction)
boolean isEnabled(String toggleName, UnleashContext context, BiFunction<String, UnleashContext Boolean> fallbackAction)

/**
* Flagsmith
*
* SDK Repo: https://github.com/Flagsmith/flagsmith-java-client
*/
boolean hasFeatureFlag(String featureId)
boolean hasFeatureFlag(String featureId, FeatureUser user)
boolean hasFeatureFlag(String featureId, FlagsAndTraits flagsAndTraits)

/**
* LaunchDarkly
*
* SDK Repo: https://github.com/launchdarkly/java-server-sdk
*/
boolean boolVariation(String featureKey, LDUser user, boolean defaultValue)
// Response also contains evaluation details
EvaluationDetail<Boolean> boolVariationDetail(String featureKey, LDUser user, boolean defaultValue)

/**
* Split
*
* SDK Repo: https://github.com/splitio/java-client
*
* NOTE: Not supported
* NOTE: Split always returns a string but using the values "on" and "off" is a common practice.
*/

/**
* CloudBees Rollout
*
* SDK Repo: N/A
*
* NOTE: Flags are configured as code and contain default values.
*
*/

boolean isEnabled(): boolean;
boolean isEnabled(Context context): boolean;

// example usage
public class Flags implements RoxContainer {
  public RoxFlag videoChat = new RoxFlag();
}
Flags flags = new Flags();
Rox.register("test-namespace", flags);
flags.videoChat.enabled

// Dynamic API
Rox.dynamicApi.isEnabled('system.reportAnalytics', false);
Rox.dynamicApi.isEnabled('system.reportAnalytics', false, context);

/**
* Harness
*
* SDK Repo: https://github.com/harness/ff-java-server-sdk
*/
boolean boolVariation(String key, Target target, boolean defaultValue)
```

</details>

<details>
  <summary>NodeJS</summary>

```typescript
/**
* Unleash
*
* SDK Repo: https://github.com/Unleash/unleash-client-node
*/
isEnabled(name: string, context?: Context, fallbackFunction?: FallbackFunction): boolean;
isEnabled(name: string, context?: Context, fallbackValue?: boolean): boolean;
isEnabled(name: string, context: Context = {}, fallback?: FallbackFunction | boolean): boolean;

/**
* Flagsmith
*
* SDK Repo: https://github.com/Flagsmith/flagsmith-nodejs-client
*/
hasFeature(key: string): Promise<boolean>
hasFeature(key: string, userId: string): Promise<boolean>

/**
* LaunchDarkly
*
* SDK Repo: https://github.com/launchdarkly/node-client-sdk
*
* Note: TS typings assign LDFlagValue = any;
* Note: variation values can be defined as boolean, number, or string. Documentation suggests casting: https://docs.launchdarkly.com/sdk/client-side/node-js#getting-started
*/

variation(
key: string,
  user: LDUser,
  defaultValue: LDFlagValue,
  callback?: (err: any, res: LDFlagValue) => void
): Promise<LDFlagValue>
// Response also contains evaluation details
variationDetail(
  key: string,
  user: LDUser,
  defaultValue: LDFlagValue,
  callback?: (err: any, res: LDEvaluationDetail) => void
): Promise<LDEvaluationDetail>;

/**
* Split
*
* SDK Repo: https://github.com/splitio/javascript-client
*
* NOTE: Not supported
* NOTE: TS typings assign Treatment = string;
* NOTE: Split always returns a string but using the values "on" and "off" is a common practice.
*/

/**
* CloudBees Rollout
*
* SDK Repo: N/A
*
* NOTE: Flags are configured as code and contain default values.
*
*/

isEnabled(context?: unknown): boolean;

// example usage
const flags = {
  videoChat: new Rox.Flag()
};

Rox.register('test-namespace', flags);
flags.videoChat.isEnabled()
flags.videoChat.isEnabled(context)

/**
* Harness
*
* SDK Repo: https://github.com/harness/ff-nodejs-server-sdk
*/
boolVariation(
  identifier: string,
  target: Target,
  defaultValue: boolean = true,
): Promise<boolean>
```

</details>

### String

<details>
  <summary>Java</summary>

```java
/**
* Unleash
*
* SDK Repo: https://github.com/Unleash/unleash-client-java
*
* NOTE: Variants can contain string, csv, or JSON
*/
Variant getVariant(final String toggleName)
Variant getVariant(final String toggleName, final UnleashContext context)
Variant getVariant(final String toggleName, final Variant defaultValue)
Variant getVariant(final String toggleName, final UnleashContext context, final Variant defaultValue)

/**
* Flagsmith
*
* SDK Repo: https://github.com/Flagsmith/flagsmith-java-client
*/
String getFeatureFlagValue(String featureId)
String getFeatureFlagValue(String featureId, FeatureUser user)
String getFeatureFlagValue(String featureId, FlagsAndTraits flagsAndTraits)

/**
* LaunchDarkly
*
* SDK Repo: https://github.com/launchdarkly/java-server-sdk
*/
String stringVariation(String featureKey, LDUser user, boolean defaultValue)
// Response also contains evaluation details
EvaluationDetail<String> stringVariationDetail(String featureKey, LDUser user, boolean defaultValue)

/**
* Split
*
* SDK Repo: https://github.com/splitio/java-client
*/
String getTreatment(String key, String split)
String getTreatment(String key, String split, Map<String, Object> attributes)
String getTreatment(Key key, String split, Map<String, Object> attributes)

/**
* CloudBees Rollout
*
* SDK Repo: N/A
*
* NOTE: Flags are configured as code and contain default values.
*
*/

String getValue();
String getValue(Context context);

// example usage:
public class Flags implements RoxContainer{
  public RoxVariant titleColors = new RoxVariant("White", new String[] {"White", "Blue", "Green", "Yellow"});
}

Flags flags = new Flags();
Rox.register("test-namespace", flags);

flags.titleColors.getValue()
flags.titleColors.getValue(context)

// Dynamic API
Rox.dynamicApi.value('ui.textColor', "red");
Rox.dynamicApi.value('ui.textColor', "red", context);

/**
* Harness
*
* SDK Repo: https://github.com/harness/ff-java-server-sdk
*/
String stringVariation(String key, Target target, String defaultValue)
```

</details>

<details>
  <summary>NodeJS</summary>

```typescript
/**
* Unleash
*
* SDK Repo: https://github.com/Unleash/unleash-client-node
* NOTE: Variants can contain string, csv, or JSON
*/
getVariant(name: string, context: Context = {}, fallbackVariant?: Variant): Variant

/**
* Flagsmith
*
* SDK Repo: https://github.com/Flagsmith/flagsmith-nodejs-client
*/
getValue(key: string): Promise<string | number | boolean>;
getValue(key: string, userId: string): Promise<string | number | boolean>;

/**
* LaunchDarkly
*
* SDK Repo: https://github.com/launchdarkly/node-client-sdk
*
* Note: TS typings assign LDFlagValue = any;
* Note: variation values can be defined as boolean, number, or string. Documentation suggests casting: https://docs.launchdarkly.com/sdk/client-side/node-js#getting-started
*/
variation(
key: string,
  user: LDUser,
  defaultValue: LDFlagValue,
  callback?: (err: any, res: LDFlagValue) => void
): Promise<LDFlagValue>
// Response also contains evaluation details
variationDetail(
  key: string,
  user: LDUser,
  defaultValue: LDFlagValue,
  callback?: (err: any, res: LDEvaluationDetail) => void
): Promise<LDEvaluationDetail>;

/**
* Split
*
* SDK Repo: https://github.com/splitio/javascript-client
*
* Note: TS typings assign Treatment = string;
* NOTE: Split always returns a string.
*
*/
getTreatment(key: SplitKey, splitName: string, attributes?: Attributes): Treatment
getTreatment(splitName: string, attributes?: Attributes): Treatment

/**
* CloudBees Rollout
*
* SDK Repo: N/A
*
* NOTE: Flags are configured as code and contain default values.
*
*/

getValue(context?: unknown): string;

// example usage
const flags = {
  titleColors: new RoxString('White', ['White', 'Blue', 'Green', 'Yellow'])
};

Rox.register('test-namespace', flags);
flags.titleColors.value();

/**
* Harness
*
* SDK Repo: https://github.com/harness/ff-nodejs-server-sdk
*/
function stringVariation(
  identifier: string,
  target: Target,
  defaultValue: boolean = '',
): Promise<string>;
```

</details>

### Integers and Floats

<details>
  <summary>Java</summary>

```java
/**
* Unleash
*
* SDK Repo: https://github.com/Unleash/unleash-client-java
*
* NOTE: Not supported; strings can be parsed into numeric values
*/

/**
* Flagsmith
*
* SDK Repo: https://github.com/Flagsmith/flagsmith-java-client
*
* NOTE: Not supported; strings can be parsed into numeric values
*/

/**
* LaunchDarkly
*
* SDK Repo: https://github.com/launchdarkly/java-server-sdk
*/
int intVariation(String featureKey, LDUser user, int defaultValue)
double doubleVariation(String featureKey, LDUser user, double defaultValue)
// Response also contains evaluation details
EvaluationDetail<Integer> intVariationDetail(String featureKey, LDUser user, int defaultValue)
EvaluationDetail<Double> doubleVariationDetail(String featureKey, LDUser user, double defaultValue)

/**
* Split
*
* SDK Repo: https://github.com/splitio/java-client
*
* NOTE: Not supported; strings can be parsed into numeric values
*/

/**
* CloudBees Rollout
*
* SDK Repo: N/A
*/

int getValue();
int getValue(Context context);
double getValue();
double getValue(Context context);

// example usage
public class Container implements RoxContainer {
  public final RoxInt titleSize = new RoxInt(5, new int[]{ 8, 13 });
  public final RoxDouble specialNumber = new RoxDouble(3.14, new double[]{ 2.71, 0.577 });
}

Container flags = new Container();
Rox.register("test-namespace", flags);
flags.titleSize.getValue();
flags.specialNumber.getValue();

// Dynamic API
Rox.dynamicApi.getNumber('ui.textSize', 12);
Rox.dynamicApi.getNumber('ui.textColor', 18, context);

/**
* Harness
*
* SDK Repo: https://github.com/harness/ff-java-server-sdk
*/
double numberVariation(String key, Target target, int defaultValue)
```

</details>

<details>
  <summary>NodeJS</summary>

```typescript
/**
* Unleash
*
* SDK Repo: https://github.com/Unleash/unleash-client-node
*
* NOTE: Not supported; Strings can be parsed into numeric values.
*/

/**
* Flagsmith
*
* SDK Repo: https://github.com/Flagsmith/flagsmith-nodejs-client
*/
getValue(key: string): Promise<string | number | boolean>;
getValue(key: string, userId: string): Promise<string | number | boolean>;

/**
* LaunchDarkly
*
* SDK Repo: https://github.com/launchdarkly/node-client-sdk
*
* Note: TS typings assign LDFlagValue = any;
* Note: variation values can be defined as boolean, number, or string. Documentation suggests casting: https://docs.launchdarkly.com/sdk/client-side/node-js#getting-started
*/
variation(
key: string,
  user: LDUser,
  defaultValue: LDFlagValue,
  callback?: (err: any, res: LDFlagValue) => void
): Promise<LDFlagValue>
// Response also contains evaluation details
variationDetail(
  key: string,
  user: LDUser,
  defaultValue: LDFlagValue,
  callback?: (err: any, res: LDEvaluationDetail) => void
): Promise<LDEvaluationDetail>;

/**
* Split
*
* SDK Repo: https://github.com/splitio/javascript-client
*
* NOTE: Not supported; Strings can be parsed into numeric values.
* NOTE: TS typings assign Treatment = string;
*/

/**
* CloudBees Rollout
*
* SDK Repo: N/A
*
* NOTE: Flags are configured as code and contain default values.
*
*/

getValue(context?: unknown): number;

// example usage
const flags = {
  titleSize: new RoxNumber(12, [12, 14, 18, 24])
};

Rox.register('test-namespace', flags);
flags.titleSize.value();

/**
* Harness
*
* SDK Repo: https://github.com/harness/ff-nodejs-server-sdk
*/
function numberVariation(
  identifier: string,
  target: Target,
  defaultValue: boolean = 1.0,
): Promise<number>;
```

</details>

### JSON

<details>
  <summary>Java</summary>

```java
/**
* Unleash
*
* SDK Repo: https://github.com/Unleash/unleash-client-java
*
* NOTE: Variants can contain string, csv, or JSON
*
*/
Variant getVariant(final String toggleName)
Variant getVariant(final String toggleName, final UnleashContext context)
Variant getVariant(final String toggleName, final Variant defaultValue)
Variant getVariant(final String toggleName, final UnleashContext context, final Variant defaultValue)

/**
* Flagsmith
*
* SDK Repo: https://github.com/Flagsmith/flagsmith-java-client
*
* NOTE: Not supported
*/

/**
* LaunchDarkly
*
* SDK Repo: https://github.com/launchdarkly/java-server-sdk
*
* Note: TS typings assign LDFlagValue = any;
* Note: variation values can be defined as boolean, number, or string; JSON structures can be encoded as strings.
*/

/**
* Split
*
* SDK Repo: https://github.com/splitio/java-client
*/
SplitResult getTreatmentWithConfig(String key, String split)
SplitResult getTreatmentWithConfig(String key, String split, Map<String, Object> attributes)
SplitResult getTreatmentWithConfig(Key key, String split, Map<String, Object> attributes)

/**
* CloudBees Rollout
*
* SDK Repo: N/A
*
* NOTE: Not supported
*/

/**
* Harness
*
* SDK Repo: https://github.com/harness/ff-java-server-sdk
*/
JsonObject jsonVariation(String key, Target target, JsonObject defaultValue)
```

</details>

<details>
  <summary>NodeJS</summary>

```typescript
/**
* Unleash
*
* SDK Repo: https://github.com/Unleash/unleash-client-node
*
* NOTE: Variants support JSON, CSV, and String payloads types, but the SDK seems to only have "String" enumerated: https://github.com/Unleash/unleash-client-node/blob/5da3b2980da63bd899619a3e558cab7874c2dbe0/src/variant.ts#L7
*/
getVariant(name: string, context: Context, fallbackVariant?: Variant): Variant

/**
* Flagsmith
*
* SDK Repo: https://github.com/Flagsmith/flagsmith-nodejs-client
*
* NOTE: Not supported; JSON structures can be encoded as strings.
*/

/**
* LaunchDarkly
*
* SDK Repo: https://github.com/launchdarkly/node-client-sdk
*
* Note: TS typings assign LDFlagValue = any;
* Note: variation values can be defined as boolean, number, or string; JSON structures can be encoded as strings.
*/

/**
* Split
*
* SDK Repo: https://github.com/splitio/javascript-client
*
* NOTE: TreatmentWithConfig contains a "config" property, which is a stringified version of the configuration JSON object
*
*/
getTreatmentWithConfig(key: SplitKey, splitName: string, attributes?: Attributes): TreatmentWithConfig,
getTreatmentWithConfig(splitName: string, attributes?: Attributes): TreatmentWithConfig,

/**
* CloudBees Rollout
*
* SDK Repo: N/A
*
* NOTE: Not supported; JSON structures can be encoded as strings.
*
*/

/**
* Harness
*
* SDK Repo: https://github.com/harness/ff-nodejs-server-sdk
*/
function jsonVariation(
  identifier: string,
  target: Target,
  defaultValue: object = {},
): Promise<Record<string, unknown>>;
```

</details>

## Attributes for flag evaluation

Most feature flag implementations support the inclusion of contextual attributes as the basis for differential evaluation of feature flags based on rules that can be defined in the flag system. Below is a summary of how various vendors allow these attributes to be supplied in flag evaluation, the types they support, and the terminology they use.

| Provider x attribute concepts | Unleash                 | Flagsmith             | LaunchDarkly                | Split                       | CloudBees             | Harness            |
| ----------------------------- | ----------------------- | --------------------- | --------------------------- | --------------------------- | --------------------- | ------------------ |
| nomenclature                  | "context", "properties" | "user", "traits"      | "user", "attributes"        | "attributes"                | "context"             | "target"           |
| standard attributes           | :heavy_check_mark:      |                       | :heavy_check_mark:          |                             | :heavy_check_mark:    |                    |
| custom attributes             | :heavy_check_mark:      | :heavy_check_mark:    |                             | :heavy_check_mark:          | :heavy_check_mark:    | :heavy_check_mark: |
| nested custom attributes      |                         |                       |                             |                             | :heavy_check_mark:    |                    |
| user key                      | `userId`                | `identifier`          | `key`                       | `key`\*                     | `distinct_id`         | `identifier`\*     |
| custom attribute types        | string                  | boolean,string,number | boolean,number,string,Array | boolean,number,string,Array | boolean,number,string | number,string\*\*  |

\* not a field, provided as distinct parameter in flag evaluation

\*\* possibly more? Documentation is unclear

<details>
  <summary>Unleash</summary>

The unleash context is an object used to store data for use in flag evaluation. A number of fields are defined by default, and additional custom fields can be specified. Some fields within the context are "static", provided at initialization, immutable for the lifetime of the application, while others are dynamic and can change with each evaluation.

```
interface Context {
  string environment?;     // static
  string appName?;         // static
  Date currentTime?;
  string userId?;
  string sessionId?;
  string remoteAddress?;
  Map<string, string | undefined | number> properties?;
}
```

see: https://docs.getunleash.io/user_guide/unleash_context

</details>

<details>
  <summary>Flagsmith</summary>

Flagsmith associates "traits" (attributes) on the user object using that user's userId. Traits can be booleans, numbers, or strings.

### v1 SDK:

```
flagsmith.setTrait(userId, key, value);

```

see: https://docs.flagsmith.com/basic-features/managing-identities#identity-traits

### v2-beta SDK:

```
await this.client.getIdentityFlags(
  identifier,
  traits // this is a "dictionary"/key-value map
)
```

</details>

<details>
  <summary>LaunchDarkly</summary>

The "user" object must be passed in every flag evaluation, and defines a key to identify a users, as well as a number of pre-defined optional properties which can be used in flag evaluation logic. Additional custom properties can be specified in the nested `custom` property.

```
interface LDUser {
    string key;
    string secondary?;
    string name?;
    string firstName?;
    string lastName?;
    string email?;
    string avatar?;
    string ip?;
    string country;
    boolean anonymous?;
    Map<string, string | boolean | number | Array<string | boolean | number>> custom?
    privateAttributeNames?: Array<string>;
  }
```

see: https://docs.launchdarkly.com/home/users/attributes

</details>

<details>
  <summary>Split</summary>

Attributes are custom data that can be used in targeting rules, which can be optionally supplied during flag evaluation.

Note: the user `key` identifies a user and is a distinct, required parameter in the split SDKs.

see: https://help.split.io/hc/en-us/articles/360020793231-Target-with-custom-attributes

</details>

<details>
  <summary>CloudBees</summary>

Properties are arbitrary data which can be used in flag evaluation. Cloudbees FM defines a few standard properties (`app_release`, `language`, `platform`, `screen_height` and `screen_width`), and allows custom properties to be defined. Note that the Cloudbees SDK requires the application author to explicitly define custom attributes. The context object passed at flag evaluation time can be used to compute properties.

```
// define a new property, using the context object to set it's value.
Rox.setCustomBooleanProperty('my-new-prop', (context) => {
  return context.myPropValue;
});
```

```
// pass the context into flag evaluation:
var context = { myPropValue = true };
Rox.dynamicApi.isEnabled('my-flag', false, context);
```

see: https://docs.cloudbees.com/docs/cloudbees-feature-management/latest/feature-releases/custom-properties

</details>

<details>
  <summary>Harness</summary>

A "target" is a conceptual user whose experience can be differentially impacted by "targeting rules". Harness defines a few standard properties (an `identifier`, a `name`, and an `anonymous` boolean), as well as a map of arbitrary custom attributes. The target is a required parameter for every flag evaluation.

```
Target {
  string identifier;
  string name;
  boolean anonymous;
  Map<string, unknown> attributes;
}
```

see: https://ngdocs.harness.io/article/xf3hmxbaji-targeting-users-with-flags#on_request_check_for_condition_and_serve_variation

</details>
