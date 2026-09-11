Feature: Provider flag evaluation

  # Verifies that a provider maps backend responses onto typed resolution details correctly.
  #
  # This does NOT test the backend's evaluation logic. Every flag in the canonical set resolves
  # to its default variant with no targeting involved, so what is under test is purely the
  # provider's mapping of a backend response to a value, a variant and a reason.
  #
  # Every success path also asserts that no error message was set (requirement 2.3.2). A
  # provider that reports a value AND an error message is sending two contradictory signals,
  # and an application reading the message will believe the wrong one.
  #
  # Requires the backend to be seeded with the canonical flag set — see flags/canonical-flags.json.

  Background:
    Given a stable provider

  Scenario Outline: Resolve values with variant and reason
    Given a <type>-flag with key "<key>" and a default value "<default>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"
    And the variant should be "<variant>"
    And the reason should be "<reason>"
    And the error-code should be ""
    And the error message should be empty
    And no exception should have been thrown

    Examples:
      | key          | type    | default | value | variant  | reason |
      | boolean-flag | Boolean | false   | true  | on       | STATIC |
      | string-flag  | String  | bye     | hi    | greeting | STATIC |
      | integer-flag | Integer | 1       | 10    | ten      | STATIC |
      | float-flag   | Float   | 0.1     | 0.5   | half     | STATIC |

  Scenario Outline: A falsy value is a value, not an absence
    # false, 0 and "" are the values most likely to be mistaken for "nothing came back": a
    # `value || default` in JavaScript, a zero-value check in Go, an `if not value` in Python.
    # Each row's default differs from its resolved value, so a provider that falls back on a
    # falsy result returns the wrong value AND the wrong reason, and is caught twice over.
    Given a <type>-flag with key "<key>" and a default value "<default>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"
    And the variant should be "<variant>"
    And the reason should be "STATIC"
    And the error-code should be ""
    And the error message should be empty
    And no exception should have been thrown

    Examples:
      | key               | type    | default  | value | variant |
      | false-flag        | Boolean | true     | false | off     |
      | zero-flag         | Integer | 1        | 0     | zero    |
      | empty-string-flag | String  | fallback |       | empty   |

  Scenario: A large integer resolves without loss of precision
    # 2147483647 is 2^31 - 1, the largest 32-bit signed integer, so every language's integer
    # accessor can ask for it. It is also outside what a 32-bit float represents exactly, so a
    # provider that routes integers through float32 and back returns 2147483648.
    Given a Integer-flag with key "large-integer-flag" and a default value "1"
    When the flag was evaluated with details
    Then the resolved details value should be "2147483647"
    And the variant should be "max-int32"
    And the reason should be "STATIC"
    And the error-code should be ""
    And no exception should have been thrown

  @large-integers
  Scenario: An integer beyond 32 bits resolves without loss of precision
    # 9007199254740991 is 2^53 - 1: the largest integer JavaScript represents exactly, and
    # comfortably inside a 64-bit integer. Anything that routes the value through a 32-bit
    # integer, or through a 64-bit float and back with rounding, changes it.
    #
    # Tagged, because whether it can be asked for at all is a property of the language's
    # SDK rather than of the provider: Java's integer accessor is a 32-bit Integer, and a
    # provider cannot resolve a value the accessor has no room for. Values above 2^53 - 1 are
    # deliberately not asked for. What a provider must do with a value that does not fit the
    # requested accessor is an open question of the provider contract (open-feature/spec#430).
    Given a Integer-flag with key "huge-integer-flag" and a default value "1"
    When the flag was evaluated with details
    Then the resolved details value should be "9007199254740991"
    And the variant should be "max-safe"
    And the reason should be "STATIC"
    And the error-code should be ""
    And no exception should have been thrown

  Scenario: An integer flag resolves as an integer
    # Paired with the float scenario below and with the narrowing scenario in errors.feature.
    # Together they pin down that the two numeric types stay distinct rather than both being
    # funnelled through one numeric representation.
    Given a Integer-flag with key "integer-flag" and a default value "1"
    When the flag was evaluated with details
    Then the resolved details value should be "10"
    And the error-code should be ""
    And the error message should be empty
    And no exception should have been thrown

  Scenario: A float flag resolves as a float
    Given a Float-flag with key "float-flag" and a default value "0.1"
    When the flag was evaluated with details
    Then the resolved details value should be "0.5"
    And the error-code should be ""
    And the error message should be empty
    And no exception should have been thrown

  @object
  Scenario: Resolve a structured value
    Given a Object-flag with key "object-flag" and a default value "{}"
    When the flag was evaluated with details
    Then the variant should be "template"
    And the reason should be "STATIC"
    And the error-code should be ""
    And the error message should be empty
    And no exception should have been thrown
    And the resolved object value should contain
      | key           | type    | value                 |
      | showImages    | Boolean | true                  |
      | title         | String  | Check out these pics! |
      | imagesPerPage | Integer | 100                   |
