@hooks
Feature: Evaluation details through hooks

# This test suite contains scenarios to test the functionality of hooks.

  Background:
    Given a provider is registered with cache disabled

  Scenario: Passes evaluation details to after and finally hooks
    Given a client with added hook
    And a boolean-flag with key "boolean-flag" and a default value "false"
    When the flag was evaluated with details
    Then "before" hooks should be called
    And "after, finally after" hooks should be called with evaluation details
      | data_type | key           | value        |
      | string    | flag_key      | boolean-flag |
      | boolean   | value         | true         |
      | string    | variant       | on           |
      | string    | reason        | STATIC       |
      | string    | error_code    | None         |
      | string    | error_message | None         |

  # errors
  Scenario: Flag not found
    Given a client with added hook
    And a string-flag with key "missing-flag" and a default value "uh-oh"
    When the flag was evaluated with details
    Then "before" hooks should be called
    And "error" hooks should be called
    And "finally after" hooks should be called with evaluation details
      | data_type | key           | value                         |
      | string    | flag_key      | missing-flag                  |
      | string    | value         | uh-oh                         |
      | string    | variant       | None                          |
      | string    | reason        | ERROR                         |
      | string    | error_code    | ErrorCode.FLAG_NOT_FOUND      |
      | string    | error_message | Flag 'missing-flag' not found |

  Scenario: Type error
    Given a client with added hook
    And a string-flag with key "wrong-flag" and a default value "13"
    When the flag was evaluated with details
    Then "before" hooks should be called
    And "error" hooks should be called
    And "finally after" hooks should be called with evaluation details
      | data_type | key           | value                                             |
      | string    | flag_key      | wrong-flag                                        |
      | integer   | value         | 13                                                |
      | string    | variant       | None                                              |
      | string    | reason        | ERROR                                             |
      | string    | error_code    | ErrorCode.TYPE_MISMATCH                           |
      | string    | error_message | Expected type <class 'int'> but got <class 'str'> |