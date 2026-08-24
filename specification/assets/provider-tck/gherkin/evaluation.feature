Feature: Provider flag evaluation

  # Verifies that a provider maps backend responses onto typed resolution details correctly.
  #
  # This does NOT test the backend's evaluation logic. Every flag in the canonical set resolves
  # to its default variant with no targeting involved, so what is under test is purely the
  # provider's mapping of a backend response to a value, a variant and a reason.
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
    And no exception should have been thrown

    Examples:
      | key          | type    | default | value | variant  | reason |
      | boolean-flag | Boolean | false   | true  | on       | STATIC |
      | string-flag  | String  | bye     | hi    | greeting | STATIC |
      | integer-flag | Integer | 1       | 10    | ten      | STATIC |
      | float-flag   | Float   | 0.1     | 0.5   | half     | STATIC |

  Scenario: An integer flag resolves as an integer
    # Paired with the float scenario below and with the narrowing scenario in errors.feature.
    # Together they pin down that the two numeric types stay distinct rather than both being
    # funnelled through one numeric representation.
    Given a Integer-flag with key "integer-flag" and a default value "1"
    When the flag was evaluated with details
    Then the resolved details value should be "10"
    And the error-code should be ""
    And no exception should have been thrown

  Scenario: A float flag resolves as a float
    Given a Float-flag with key "float-flag" and a default value "0.1"
    When the flag was evaluated with details
    Then the resolved details value should be "0.5"
    And the error-code should be ""
    And no exception should have been thrown

  @object
  Scenario: Resolve a structured value
    Given a Object-flag with key "object-flag" and a default value "{}"
    When the flag was evaluated with details
    Then the variant should be "template"
    And the reason should be "STATIC"
    And the error-code should be ""
    And no exception should have been thrown
    And the resolved object value should contain
      | key           | type    | value                 |
      | showImages    | Boolean | true                  |
      | title         | String  | Check out these pics! |
      | imagesPerPage | Integer | 100                   |
