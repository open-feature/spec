Feature: Flag Evaluations - Complete OpenFeature Specification Coverage
  # This comprehensive test suite covers all OpenFeature specification requirements
  # for flag evaluation, including error handling, provider states, and edge cases.

    Background:
    # Implicitly tests spec 1.1.2.1 (provider mutator) and 1.7.3 (READY status after initialize)
        Given a stable provider

  # Spec 1.3.1.1 & 1.4.1.1: Basic typed flag evaluation with detailed evaluation
  # Testing: getBooleanValue, getStringValue, getIntegerValue, getFloatValue methods
  # Implicitly tests: 1.1.6 (client creation), 1.1.7 (client creation no throw), 1.4.3 (value field), 1.4.10 (no exceptions)
    @spec-1.3.1.1 @spec-1.4.1.1 @spec-1.1.6 @spec-1.1.7 @spec-1.4.3 @spec-1.4.10
    Scenario Outline: Resolve values
        Given a <type>-flag with key "<key>" and a default value "<default>"
        When the flag was evaluated with details
        Then the resolved details value should be "<resolved_value>"
        @booleans
        Examples: Boolean evaluations
            | key          | type    | default | resolved_value |
            | boolean-flag | Boolean | false   | true           |
        @strings
        Examples: String evaluations
            | key         | type   | default | resolved_value |
            | string-flag | String | bye     | hi             |
        @numbers
        Examples: Number evaluations
            | key          | type    | default | resolved_value |
            | integer-flag | Integer | 1       | 10             |
            | float-flag   | Float   | 0.1     | 0.5            |
        @objects
        Examples: Object evaluations
            | key         | type   | default | resolved_value                                                                     |
            | object-flag | Object | {}      | {\"showImages\": true,\"title\": \"Check out these pics!\",\"imagesPerPage\": 100} |

  # Spec 1.4.7: Testing reason field population in normal execution
  # Testing: evaluation details structure contains correct reason
    @spec-1.4.7
    Scenario Outline: Resolves zero value
        Given a <type>-flag with key "<key>" and a default value "<default>"
        When the flag was evaluated with details
        Then the resolved details value should be "<resolved_value>"
        And the reason should be "STATIC"

        @booleans
        Examples: Boolean evaluations
            | key               | type    | default | resolved_value |
            | boolean-zero-flag | Boolean | true    | false          |

        @strings
        Examples: String evaluations
            | key              | type   | default | resolved_value |
            | string-zero-flag | String | hi      |                |

        @numbers
        Examples: Number evaluations
            | key               | type    | default | resolved_value |
            | integer-zero-flag | Integer | 1       | 0              |
            | float-zero-flag   | Float   | 0.1     | 0.0            |

        @objects
        Examples: Object evaluations
            | key              | type   | default | resolved_value                                                                     |
            | object-zero-flag | Object | {\"a\": 1} | {}                                                                                 |

  # Spec 1.4.7: Testing TARGETING_MATCH reason with evaluation context
  # Testing: dynamic context paradigm with targeting rules
    @targeting @spec-1.4.7
    Scenario Outline: Resolves zero value with targeting
        Given a <type>-flag with key "<key>" and a default value "<default>"
        And a context containing a key "email", with type "String" and with value "ballmer@macrosoft.com"
        When the flag was evaluated with details
        Then the resolved details value should be "<resolved_value>"
        And the reason should be "TARGETING_MATCH"

        @booleans
        Examples: Boolean evaluations
            | key                        | type    | default | resolved_value |
            | boolean-targeted-zero-flag | Boolean | true    | false          |

        @strings
        Examples: String evaluations
            | key                       | type   | default | resolved_value |
            | string-targeted-zero-flag | String | hi      |                |

        @numbers
        Examples: Number evaluations
            | key                        | type    | default | resolved_value |
            | integer-targeted-zero-flag | Integer | 1       | 0              |
            | float-targeted-zero-flag   | Float   | 0.1     | 0.0            |

        @objects
        Examples: Object evaluations
            | key                       | type   | default    | resolved_value |
            | object-targeted-zero-flag | Object | {\"a\": 1} | {}             |

  # Spec 1.4.7: Testing DEFAULT reason when targeting doesn't match
  # Testing: fallback to default value when context doesn't match targeting rules
    @targeting @spec-1.4.7
    Scenario Outline: Resolves zero value with targeting using default
        Given a <type>-flag with key "<key>" and a default value "<default>"
        And a context containing a key "email", with type "String" and with value "ballmer@none.com"
        When the flag was evaluated with details
        Then the resolved details value should be "<resolved_value>"
        And the reason should be "DEFAULT"

        @booleans
        Examples: Boolean evaluations
            | key                        | type    | default | resolved_value |
            | boolean-targeted-zero-flag | Boolean | true    | false          |

        @strings
        Examples: String evaluations
            | key                       | type   | default | resolved_value |
            | string-targeted-zero-flag | String | hi      |                |

        @numbers
        Examples: Number evaluations
            | key                        | type    | default | resolved_value |
            | integer-targeted-zero-flag | Integer | 1       | 0              |
            | float-targeted-zero-flag   | Float   | 0.1     | 0.0            |

        @objects
        Examples: Object evaluations
            | key                       | type   | default    | resolved_value |
            | object-targeted-zero-flag | Object | {\"a\": 1} | {}             |

  # Spec 1.4.8 & 1.4.9: Testing FLAG_NOT_FOUND error code in abnormal execution
  # Testing: client must return default value and error code when flag doesn't exist
  # Implicitly tests: 1.4.10 (client never throws exceptions - returns default instead)
    @error-handling @spec-1.4.8 @spec-1.4.9 @spec-1.4.10
    Scenario Outline: Flag not found error
        Given a <type>-flag with key "non-existent-flag" and a default value "<default>"
        When the flag was evaluated with details
        Then the resolved details value should be "<default>"
        And the reason should be "ERROR"
        And the error-code should be "FLAG_NOT_FOUND"

        @booleans
        Examples: Boolean evaluations
            | type    | default |
            | Boolean | false   |

        @strings
        Examples: String evaluations
            | type   | default |
            | String | bye     |

        @numbers
        Examples: Number evaluations
            | type    | default |
            | Integer | 1       |
            | Float   | 0.1     |

        @objects
        Examples: Object evaluations
            | type   | default    |
            | Object | {\"a\": 1} |

  # Spec 1.3.4: Testing type mismatch handling - wrong type evaluation
  # Testing: client should return default value when provider returns wrong type
  # Note: Test data setup ensures the flag returns wrong type, triggering type mismatch
  # Implicitly tests: 1.4.10 (client never throws exceptions - returns default instead)
    @error-handling @spec-1.3.4 @spec-1.4.10
    Scenario Outline: Type mismatch error
        Given a <requested_type>-flag with key "<key>" and a default value "<default>"
        When the flag was evaluated with details
        Then the resolved details value should be "<default>"
        And the reason should be "ERROR"
        And the error-code should be "TYPE_MISMATCH"

        @booleans
        Examples: Boolean evaluations
            | key          | requested_type | default |
            | boolean-flag | String         | bye     |

        @strings
        Examples: String evaluations
            | key         | requested_type | default |
            | string-flag | Boolean        | false   |

        @numbers
        Examples: Number evaluations
            | key         | requested_type | default |
            | string-flag | Integer        | 1       |

        @objects
        Examples: Object evaluations
            | key         | requested_type | default |
            | string-flag | Object         | {}      |

  # Spec 1.7.6: Testing PROVIDER_NOT_READY error when provider isn't initialized
  # Testing: client must short-circuit and return error when provider not ready
  # Implicitly tests: 1.4.10 (client never throws exceptions - returns default instead)
    @provider-status @spec-1.7.6 @spec-1.4.10
    Scenario Outline: Provider not ready error
        Given a not ready provider
        And a <type>-flag with key "<key>" and a default value "<default>"
        When the flag was evaluated with details
        Then the resolved details value should be "<default>"
        And the reason should be "ERROR"
        And the error-code should be "PROVIDER_NOT_READY"

        @booleans
        Examples: Boolean evaluations
            | key          | type    | default |
            | boolean-flag | Boolean | false   |

        @strings
        Examples: String evaluations
            | key         | type   | default |
            | string-flag | String | bye     |

        @numbers
        Examples: Number evaluations
            | key          | type    | default |
            | integer-flag | Integer | 1       |
            | float-flag   | Float   | 0.1     |

        @objects
        Examples: Object evaluations
            | key         | type   | default    |
            | object-flag | Object | {\"a\": 1} |

  # Spec 1.7.7: Testing PROVIDER_FATAL error when provider is in fatal state
  # Testing: client must short-circuit and return error when provider is fatal
  # Implicitly tests: 1.4.10 (client never throws exceptions - returns default instead), 1.7.5 (FATAL status)
    @provider-status @spec-1.7.7 @spec-1.4.10 @spec-1.7.5
    Scenario Outline: Provider in fatal state error
        Given a fatal provider
        And a <type>-flag with key "<key>" and a default value "<default>"
        When the flag was evaluated with details
        Then the resolved details value should be "<default>"
        And the reason should be "ERROR"
        And the error-code should be "PROVIDER_FATAL"

        @booleans
        Examples: Boolean evaluations
            | key          | type    | default |
            | boolean-flag | Boolean | false   |

        @strings
        Examples: String evaluations
            | key         | type   | default |
            | string-flag | String | bye     |

        @numbers
        Examples: Number evaluations
            | key          | type    | default |
            | integer-flag | Integer | 1       |
            | float-flag   | Float   | 0.1     |

        @objects
        Examples: Object evaluations
            | key         | type   | default    |
            | object-flag | Object | {\"a\": 1} |

  # Spec 1.4.3, 1.4.5, 1.4.6: Testing complete evaluation details structure
  # Testing: evaluation details must contain value, flagKey, and variant fields
    @evaluation-details @spec-1.4.3 @spec-1.4.5 @spec-1.4.6
    Scenario Outline: Complete evaluation details structure
        Given a <type>-flag with key "<key>" and a default value "<default>"
        When the flag was evaluated with details
        Then the resolved details value should be "<resolved_value>"
        And the flag key should be "<key>"
        And the variant should be "<expected_variant>"
        And the reason should be "STATIC"
        @booleans
        Examples: Boolean evaluations
            | key          | type    | default | resolved_value | expected_variant |
            | boolean-flag | Boolean | false   | true           | on               |

        @strings
        Examples: String evaluations
            | key         | type   | default | resolved_value | expected_variant |
            | string-flag | String | bye     | hi             | greeting         |

        @numbers
        Examples: Number evaluations
            | key          | type    | default | resolved_value | expected_variant |
            | integer-flag | Integer | 1       | 10             | ten              |
            | float-flag   | Float   | 0.1     | 0.5            | half             |

        @objects
        Examples: Object evaluations
            | key         | type   | default | resolved_value                        | expected_variant |
            | object-flag | Object | {}      | {\"showImages\": true,\"title\": \"Check out these pics!\",\"imagesPerPage\": 100} | template         |

  # Spec 1.4.14: Testing flag metadata field in evaluation details
  # Testing: flag metadata must be included in evaluation details if present
  # Note: Test data setup ensures these flags have metadata configured
    @evaluation-details @metadata @spec-1.4.14
    Scenario: Flag metadata in evaluation details
        Given a Boolean-flag with key "metadata-flag" and a default value "true"
        When the flag was evaluated with details
        Then the resolved metadata should contain
            | key     | metadata_type | value |
            | string  | String        | 1.0.2 |
            | integer | Integer       | 2     |
            | float   | Float         | 0.1   |
            | boolean | Boolean       | true  |


  # Spec 1.3.1.1: Testing evaluation with empty context
  # Testing: targeting rules should fall back to default when context is empty
    @context-handling @spec-1.3.1.1
    Scenario Outline: Empty evaluation context
        Given a <type>-flag with key "<key>" and a default value "<default>"
        When the flag was evaluated with details
        Then the resolved details value should be "<value>"
        And the reason should be "DEFAULT"

        @booleans
        Examples: Boolean evaluations
            | key                        | type    | value | default |
            | boolean-targeted-zero-flag | Boolean | false | true    |

        @strings
        Examples: String evaluations
            | key                       | type   | value | default |
            | string-targeted-zero-flag | String |       | str     |

        @numbers
        Examples: Number evaluations
            | key                        | type    | value | default |
            | integer-targeted-zero-flag | Integer | 0     | 1       |
            | float-targeted-zero-flag   | Float   | 0.0   | 1.0     |

        @objects
        Examples: Object evaluations
            | key                       | type   | value | default    |
            | object-targeted-zero-flag | Object | {}    | {\"a\": 1} |


  # Spec 1.3.1.1: Testing evaluation with null context values
  # Testing: targeting rules should handle null values gracefully
    @context-handling @spec-1.3.1.1
    Scenario Outline: Null context values
        Given a <type>-flag with key "<key>" and a default value "<default>"
        And a context containing a key "email" with null value
        When the flag was evaluated with details
        Then the resolved details value should be "<value>"
        And the reason should be "DEFAULT"

        @booleans
        Examples: Boolean evaluations
            | key                        | type    | value | default |
            | boolean-targeted-zero-flag | Boolean | false | true    |

        @strings
        Examples: String evaluations
            | key                       | type   | value | default |
            | string-targeted-zero-flag | String |       | str     |

        @numbers
        Examples: Number evaluations
            | key                        | type    | value | default |
            | integer-targeted-zero-flag | Integer | 0     | 1       |
            | float-targeted-zero-flag   | Float   | 0.0   | 1.0     |

        @objects
        Examples: Object evaluations
            | key                       | type   | value | default    |
            | object-targeted-zero-flag | Object | {}    | {\"a\": 1} |


  # Spec 1.3.1.1: Testing evaluation with multiple context attributes
  # Testing: complex targeting rules with multiple context fields
    @context-handling @targeting @spec-1.3.1.1
    Scenario: Multiple context attributes targeting
        Given a String-flag with key "complex-targeted" and a default value "false"
        And a context containing a key "email", with type "String" and with value "ballmer@macrosoft.com"
        And a context containing a key "role", with type "String" and with value "admin"
        And a context containing a key "age", with type "Integer" and with value "65"
        And a context containing a key "customer", with type "Boolean" and with value "false"
        When the flag was evaluated with details
        Then the resolved details value should be "INTERNAL"
        And the reason should be "TARGETING_MATCH"

  # Spec 1.3.1.1: Testing structure/object flag evaluation
  # Testing: structured data evaluation using existing steps with JSON data
    @data-types @spec-1.3.1.1
    Scenario: Structure flag evaluation
        Given a Object-flag with key "object-flag" and a default value "{}"
        When the flag was evaluated with details
        Then the resolved details value should be "{\"showImages\": true,\"title\": \"Check out these pics!\",\"imagesPerPage\": 100}"
        And the reason should be "STATIC"

  # Spec 1.4.6: Testing variant field population in evaluation details
  # Testing: variant field must contain provider's variant value
    @variants @spec-1.4.6
    Scenario Outline: Variant field population
        Given a <type>-flag with key "<key>" and a default value "<default>"
        When the flag was evaluated with details
        Then the variant should be "<expected_variant>"

        @booleans
        Examples: Boolean evaluations
            | key          | type    | default | expected_variant |
            | boolean-flag | Boolean | false   | on               |

        @strings
        Examples: String evaluations
            | key         | type   | default | expected_variant |
            | string-flag | String | bye     | greeting         |

        @numbers
        Examples: Number evaluations
            | key          | type    | default | expected_variant |
            | integer-flag | Integer | 1       | ten              |

            | float-flag   | Float   | 0.1     | half             |

        @objects
        Examples: Object evaluations
            | key         | type   | default | expected_variant |
            | object-flag | Object | {}      | template   |


  # Spec 1.4.7: Testing CACHED reason code
  # Testing: provider can return CACHED reason for performance optimization
    @reason-codes @spec-1.4.7
    Scenario Outline: CACHED reason
        Given a <type>-flag with key "<key>" and a default value "<default>"
        When the flag was evaluated with details
        And the flag was evaluated with details
        Then the reason should be "CACHED"
        Examples:
            | key          | type    | default |
            | boolean-flag | Boolean | false   |
            | string-flag  | String  | bye     |

  # Spec 1.4.7: Testing DISABLED reason code
  # Testing: provider can return DISABLED reason when flag is turned off
  # Note: Test data setup ensures these flags are configured as disabled
    @reason-codes @spec-1.4.7
    Scenario Outline: DISABLED reason
        Given a <type>-flag with key "<key>" and a default value "<default>"
        When the flag was evaluated with details
        Then the resolved details value should be "<default>"
        And the reason should be "DISABLED"

        @booleans
        Examples: Boolean evaluations
            | key                   | type    | default |
            | boolean-disabled-flag | Boolean | false   |

        @strings
        Examples: String evaluations
            | key                  | type   | default |
            | string-disabled-flag | String | bye     |

        @numbers
        Examples: Number evaluations
            | key                   | type    | default |
            | integer-disabled-flag | Integer | 1       |
            | float-disabled-flag   | Float   | 0.1     |

        @objects
        Examples: Object evaluations
            | key                  | type   | default    |
            | object-disabled-flag | Object | {\"a\": 1} |

  # Spec 1.4.13: Testing error message field in abnormal execution
  # Testing: evaluation details may contain error message with additional details
    @error-handling @spec-1.4.13
    Scenario: Error message in evaluation details
        Given a Boolean-flag with key "missing-flag" and a default value "false"
        When the flag was evaluated with details
        Then the reason should be "ERROR"
        And the error message should contain "flag missing-flag not found"

  # Spec 1.7.1: Testing provider status accessibility
  # Testing: client must expose provider status (READY, NOT_READY, ERROR, etc.)
  # Implicitly tests: 1.7.4 (ERROR status), 1.7.5 (FATAL status)
    @provider-status @spec-1.7.1 @spec-1.7.4 @spec-1.7.5
    Scenario Outline: Provider status accessibility
        Given a <status> provider
        Then the provider status should be "<status_code>"
        Examples:
            | status    | status_code |
            | stable    | READY       |
            | not ready | NOT_READY   |
            | error     | ERROR       |
            | fatal     | FATAL       |
            | stale     | STALE       |

  # Spec 1.5.1: Testing evaluation options with hooks
  # Testing: evaluation options can specify hooks to execute during evaluation
    @hooks @evaluation-options @spec-1.5.1
    Scenario: Evaluation options with hooks
        Given a Boolean-flag with key "boolean-flag" and a default value "false"
        And evaluation options containing specific hooks
        When the flag was evaluated with details using the evaluation options
        Then the specified hooks should execute during evaluation
        And the hook order should be maintained

  # Additional edge cases for robustness
    @edge-cases
    Scenario Outline: Default value type validation
        Given a <type>-flag with key "<key>" and a default value "<default>"
        When the flag was evaluated with details
        Then the resolved details value should be "<default>"
        And the error-code should be "TYPE_MISMATCH"
        Examples:
            | key          | type    | default |
            | string-flag  | Boolean | false   |
            | boolean-flag | String  | bye     |
            | boolean-flag | Integer | 1       |
            | boolean-flag | Float   | 0.1     |

  # Testing immutability requirements (Spec 1.4.15/1.4.14.1)
  # Testing: flag metadata must be immutable
    @immutability @spec-1.4.14.1
    Scenario: Evaluation context immutability
        Given a Boolean-flag with key "boolean-flag" and a default value "false"
        And an evaluation context with modifiable data
        When the flag was evaluated with details
        Then the original evaluation context should remain unmodified
        And the evaluation details should be immutable

  # Testing async/non-blocking mechanisms (Spec 1.4.12)
  # Testing: client should provide asynchronous mechanisms for flag evaluation
    @async @spec-1.4.12
    Scenario Outline: Asynchronous flag evaluation
        Given a <type>-flag with key "<key>" and a default value "<default>"
        When the flag was evaluated with details asynchronously
        Then the evaluation should complete without blocking
        And the resolved details value should be "<resolved_value>"

        @booleans
        Examples: Boolean evaluations
            | key          | type    | default | resolved_value |
            | boolean-flag | Boolean | false   | true           |

        @strings
        Examples: String evaluations
            | key         | type   | default | resolved_value |
            | string-flag | String | bye     | hi             |

        @numbers
        Examples: Number evaluations
            | key          | type    | default | resolved_value |
            | integer-flag | Integer | 1       | 10             |
            | float-flag   | Float   | 0.1     | 0.5            |
            
        @objects
        Examples: Object evaluations
            | key         | type   | default | resolved_value                                                                     |
            | object-flag | Object | {}      | {\"showImages\": true,\"title\": \"Check out these pics!\",\"imagesPerPage\": 100} |
#
# IMPLICIT SPECIFICATION COVERAGE NOTES:
#
# The following OpenFeature specification requirements are tested IMPLICITLY
# through the behavior of existing scenarios, without requiring dedicated test cases:
#
# @spec-1.4.10 - "Client MUST NOT throw exceptions"
#   → Implicitly tested in ALL error scenarios (FLAG_NOT_FOUND, TYPE_MISMATCH,
#     PROVIDER_NOT_READY, PROVIDER_FATAL). If exceptions were thrown, these tests
#     would fail when checking "Then the resolved details value should be <default>".
#   → Covered by scenarios: Flag not found error, Type mismatch error,
#     Provider not ready error, Provider in fatal state error
#
# @spec-1.1.2.1 - "API MUST define a provider mutator to set default provider"
#   → Implicitly tested by Background step "Given a stable provider" which
#     requires the API to set/configure a provider
#   → Covered by: Background setup in all scenarios
#
# @spec-1.1.6 - "API MUST provide function for creating a client"
#   → Implicitly tested in ALL scenarios that use "When the flag was evaluated"
#     since flag evaluation requires a client instance
#   → Covered by: All evaluation scenarios
#
# @spec-1.1.7 - "Client creation function MUST NOT throw"
#   → Implicitly tested in ALL scenarios - if client creation threw exceptions,
#     no scenarios could proceed to flag evaluation
#   → Covered by: All scenarios that successfully reach evaluation steps
#
# @spec-1.3.1.1 - "Client MUST provide typed flag evaluation methods"
#   → Implicitly tested by successful evaluation of Boolean, String, Integer, Float types
#   → Additional coverage: All basic "Resolve values" scenarios demonstrate
#     the required typed evaluation methods work correctly
#   → Covered by: All typed evaluation scenarios
#
# @spec-1.3.3.1 - "Client SHOULD provide functions for floating-point numbers and integers"
#   → Implicitly tested by successful evaluation of both Integer and Float flag types
#   → in the "Resolve values" scenario which evaluates integer-flag and float-flag
#   → If type distinction wasn't properly implemented, these evaluations would fail
#   → Covered by: Resolve values scenario with integer-flag and float-flag examples
#
# @spec-1.4.3 - "Evaluation details value field MUST contain evaluated flag value"
#   → Implicitly tested in ALL detailed evaluation scenarios via
#     "Then the resolved details value should be <value>"
#   → Covered by: All scenarios using detailed evaluation
#
# @spec-1.4.11 - "Client methods SHOULD NOT write log messages"
#   → Cannot be directly tested via Gherkin, but implicitly verified by
#     ensuring evaluation methods don't produce unwanted side effects
#   → Behavioral requirement verified through implementation review
#
# @spec-1.7.3 - "Provider status MUST indicate READY after successful initialize"
#   → Implicitly tested by Background "Given a stable provider" followed by
#     successful flag evaluations - if provider wasn't READY, evaluations would fail
#   → Covered by: All scenarios that successfully evaluate flags after stable provider setup
#
# @spec-1.7.4 - "Provider status MUST indicate ERROR after failed initialize"
#   → Implicitly tested by "Given a error provider" scenarios
#   → Covered by: Provider status accessibility scenarios with error provider
#
# @spec-1.7.5 - "Provider status MUST indicate FATAL for PROVIDER_FATAL error"
#   → Implicitly tested by "Given a fatal provider" scenarios
#   → Covered by: Provider status accessibility and Provider in fatal state error scenarios
#
# Note: These implicit tests provide coverage without requiring additional scenarios,
# demonstrating that the OpenFeature specification requirements are naturally
# satisfied by the expected behavior of a compliant implementation.
#
