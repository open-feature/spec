# API Comparison

The goal of this research is to make it easy to quickly compare feature flag
vendor SDK API's in order to help define the OpenFeature spec.

## Types

| Provider | Unleash | Flagsmith | LaunchDarkly | Split | Cloudbees Rollout | Harness |
| -------- | ------- | --------- | ------------ | ----- | ----------------- | ------- |
| boolean  | :heavy_check_mark:    | :heavy_check_mark:      | :heavy_check_mark:         |       | :heavy_check_mark:              | :heavy_check_mark:    |
| string   | :heavy_check_mark:    | :heavy_check_mark:      | :heavy_check_mark:         | :heavy_check_mark:  | :heavy_check_mark:              | :heavy_check_mark:    |
| numeric  |         |           | :heavy_check_mark:         |       | :heavy_check_mark:              | :heavy_check_mark:    |
| JSON     | :heavy_check_mark:    |           |              | :heavy_check_mark:  |                   | :heavy_check_mark:    |

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
  defaultValue: boolean = {},
): Promise<Record<string, unknown>>;
```

</details>