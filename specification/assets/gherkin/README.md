# Test Assets

This directory contains test assets for the OpenFeature specification, including Gherkin test scenarios and structured JSON test data for comprehensive implementation validation.

## Overview

The test assets improve the existing Gherkin test suite by providing structured JSON test data that eliminates the need for manual test data creation. The data includes various flag types with different targeting scenarios to test edge cases and standard behavior.

## Test Data Structure (`test-flags.json`)

The [JSON test data](./test-flags.json) contains flags organized into several categories based on their behavior and purpose:

### Standard Flags
Basic feature flags with straightforward evaluation:
- `boolean-flag`: Boolean flag with variants `on` (true) and `off` (false), defaults to `on`
- `string-flag`: String flag with variants `greeting` ("hi") and `parting` ("bye"), defaults to `greeting`
- `integer-flag`: Integer flag with variants `one` (1) and `ten` (10), defaults to `ten`
- `float-flag`: Float flag with variants `tenth` (0.1) and `half` (0.5), defaults to `half`
- `object-flag`: Object flag with `empty` ({}) and `template` variants, defaults to `template`

### Zero Value Flags
Flags specifically designed to test zero/empty value handling:
- `boolean-zero-flag`: Boolean flag that defaults to `zero` variant (false)
- `string-zero-flag`: String flag that defaults to `zero` variant (empty string "")
- `integer-zero-flag`: Integer flag that defaults to `zero` variant (0)
- `float-zero-flag`: Float flag that defaults to `zero` variant (0.0)
- `object-zero-flag`: Object flag that defaults to `zero` variant (empty object {})

### Targeted Zero Flags
Flags with CEL expressions that can evaluate to zero values based on context:
- `boolean-targeted-zero-flag`: Uses CEL targeting, defaults to `zero` (false)
- `string-targeted-zero-flag`: Uses CEL targeting, defaults to `zero` (empty string)
- `integer-targeted-zero-flag`: Uses CEL targeting, defaults to `zero` (0)
- `float-targeted-zero-flag`: Uses CEL targeting, defaults to `zero` (0.0)
- `object-targeted-zero-flag`: Uses CEL targeting, defaults to `zero` (empty object)

### Disabled Flags
Flags that are statically disabled:
- `boolean-disabled-flag`: Disabled Flag
- `string-disabled-flag`: Disabled Flag
- `integer-disabled-flag`: Disabled Flag
- `float-disabled-flag`: Disabled Flag
- `object-disabled-flag`: Disabled Flag

### Special Testing Flags
Flags for testing edge cases and metadata:
- `metadata-flag`: Boolean flag with rich metadata including string, integer, boolean, and float values
- `complex-targeted`: String flag with complex CEL expression for internal/external user distinction
- `null-default-flag`: Flag with explicitly null default variant
- `undefined-default-flag`: Flag with no default variant defined
- `wrong-flag`: Flag for testing error scenarios

## CEL Expression Variables

The test data uses Common Expression Language (CEL) expressions in the `contextEvaluator` field. Based on the expressions in the test data, the following context variables are expected:

### Available Context Variables
- `email`: User's email address (string)
- `customer`: Boolean flag indicating customer status
- `age`: User's age (integer)

### CEL Expressions Used

#### Simple Email Targeting
```cel
email == 'ballmer@macrosoft.com' ? 'zero' : ''
```
Used in: `boolean-targeted-zero-flag`, `string-targeted-zero-flag`, `integer-targeted-zero-flag`, `float-targeted-zero-flag`, `object-targeted-zero-flag`

#### Complex Multi-Condition Targeting
```cel
!customer && email == 'ballmer@macrosoft.com' && age > 10 ? 'internal' : ''
```
Used in: `complex-targeted`

## Flag Structure Schema

Each flag in the test data follows this structure:

```json
{
  "flag-name": {
    "variants": {
      "variant-key": "variant-value"
    },
    "defaultVariant": "variant-key-or-null",
    "contextEvaluator": "CEL-expression", // Optional
    "flagMetadata": {} // Optional
  }
}
```

### Key Components
- **variants**: Object containing all possible flag values mapped to variant keys
- **defaultVariant**: The variant key to use when no targeting rules match (can be null or omitted)
- **contextEvaluator**: Optional CEL expression for dynamic targeting
- **flagMetadata**: Optional metadata object containing additional flag information

## Usage

1. **Test Implementation**: Parse the JSON file with your preferred JSON library
2. **Context Setup**: Ensure your test contexts include the required variables (`email`, `customer`, `age`)
3. **CEL Evaluation**: Implement CEL expression evaluation for flags with `contextEvaluator`
4. **Edge Case Testing**: Use the zero flags and special flags to test boundary conditions

## Test Context Examples

For comprehensive testing, use these context combinations:

```json
// Triggers targeted zero variants
{
  "targetingKey": "user1",
  "email": "ballmer@macrosoft.com",
  "customer": false,
  "age": 25
}

// Triggers complex targeting
{
  "targetingKey": "user2",
  "email": "ballmer@macrosoft.com",
  "customer": false,
  "age": 15
}

// Triggers alternative targeting
{
  "targetingKey": "user3",
  "email": "jobs@orange.com"
}

// Default behavior (no targeting matches)
{
  "targetingKey": "user4",
  "email": "test@example.com",
  "customer": true,
  "age": 30
}
```

## Contributing

When modifying test data:
1. Maintain the category structure (standard, zero, targeted-zero, disabled)
2. Validate CEL expressions for syntax correctness
3. Ensure all required context variables are documented
4. Test both matching and non-matching targeting scenarios
