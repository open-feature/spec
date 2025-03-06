@hooks
Feature: Evaluation details through hooks

# This test suite contains scenarios to test the functionality of hooks.

  Background:
    Given a stable provider

  Scenario: Passes evaluation details to after and finally hooks
    Given a client with added hook
    And a boolean-flag with key "boolean-flag" and a default value "false"
    When the flag was evaluated with details
    Then the "before" hook should have been executed
    And the "after, finally" hooks should be called with evaluation details
      | data_type | key        | value        |
      | string    | flag_key   | boolean-flag |
      | boolean   | value      | true         |
      | string    | variant    | on           |
      | string    | reason     | STATIC       |
      | string    | error_code | null         |

  # errors
  Scenario: Flag not found
    Given a client with added hook
    And a string-flag with key "missing-flag" and a default value "uh-oh"
    When the flag was evaluated with details
    Then the "before" hook should have been executed
    And the "error" hook should have been executed
    And the "finally" hooks should be called with evaluation details
      | data_type | key        | value          |
      | string    | flag_key   | missing-flag   |
      | string    | value      | uh-oh          |
      | string    | variant    | null           |
      | string    | reason     | ERROR          |
      | string    | error_code | FLAG_NOT_FOUND |

  Scenario: Type error
    Given a client with added hook
    And a boolean-flag with key "wrong-flag" and a default value "false"
    When the flag was evaluated with details
    Then the "before" hook should have been executed
    And the "error" hook should have been executed
    And the "finally" hooks should be called with evaluation details
      | data_type | key        | value         |
      | string    | flag_key   | wrong-flag    |
      | boolean   | value      | false         |
      | string    | variant    | null          |
      | string    | reason     | ERROR         |
      | string    | error_code | TYPE_MISMATCH |
