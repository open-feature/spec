Feature: Provider error handling

  # Every scenario here asserts the same three-part contract, because all three parts matter and
  # providers routinely get one of them wrong:
  #
  #   1. the code default is returned — an application must keep working,
  #   2. the correct error code is reported — an application must be able to tell what went wrong,
  #   3. nothing is thrown — an unhandled exception from a flag evaluation is never acceptable.
  #
  # Requires the backend to be seeded with the canonical flag set — see flags/canonical-flags.json.

  Background:
    Given a stable provider

  Scenario Outline: Requesting the wrong type returns the code default
    # The full non-numeric mismatch matrix. Numeric coercion is a separate question and is covered
    # by the @strict-numeric-typing scenarios below, because "is 0.5 an integer?" has a defensible
    # wrong answer whereas "is a string a boolean?" does not.
    Given a <requested>-flag with key "<key>" and a default value "<default>"
    When the flag was evaluated with details
    Then the resolved details value should be "<default>"
    And the reason should be "ERROR"
    And the error-code should be "TYPE_MISMATCH"
    And no exception should have been thrown

    Examples: a string flag requested as something else
      | key         | requested | default  |
      | string-flag | Boolean   | false    |
      | string-flag | Integer   | 1        |
      | string-flag | Float     | 0.1      |
      | wrong-flag  | Boolean   | false    |

    Examples: a boolean flag requested as something else
      | key          | requested | default  |
      | boolean-flag | String    | fallback |
      | boolean-flag | Integer   | 1        |
      | boolean-flag | Float     | 0.1      |

    Examples: a numeric flag requested as a non-numeric type
      | key          | requested | default  |
      | integer-flag | Boolean   | false    |
      | integer-flag | String    | fallback |
      | float-flag   | Boolean   | false    |
      | float-flag   | String    | fallback |

  @object
  Scenario Outline: Requesting a structured flag as a scalar returns the code default
    Given a <requested>-flag with key "object-flag" and a default value "<default>"
    When the flag was evaluated with details
    Then the resolved details value should be "<default>"
    And the reason should be "ERROR"
    And the error-code should be "TYPE_MISMATCH"
    And no exception should have been thrown

    Examples:
      | requested | default  |
      | Boolean   | false    |
      | String    | fallback |
      | Integer   | 1        |
      | Float     | 0.1      |

  @strict-numeric-typing
  Scenario: A float flag is not silently narrowed to an integer
    # 'float-flag' resolves to 0.5. Narrowing that to an integer would lose information
    # silently, so it must be reported as a type mismatch rather than rounded.
    Given a Integer-flag with key "float-flag" and a default value "1"
    When the flag was evaluated with details
    Then the resolved details value should be "1"
    And the reason should be "ERROR"
    And the error-code should be "TYPE_MISMATCH"
    And no exception should have been thrown

  Scenario: An unknown flag key returns the code default
    # 'missing-flag' is deliberately absent from the canonical flag set.
    Given a String-flag with key "missing-flag" and a default value "fallback"
    When the flag was evaluated with details
    Then the resolved details value should be "fallback"
    And the reason should be "ERROR"
    And the error-code should be "FLAG_NOT_FOUND"
    And no exception should have been thrown
