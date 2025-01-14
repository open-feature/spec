@Metadata
Feature: Metadata

  Background:
    Given a provider is registered

  Scenario: Returns metadata
    Given a Boolean-flag with key "metadata-flag" and a default value "true"
    When the flag was evaluated with details
    Then the resolved metadata should contain
      | key     | metadata_type | value |
      | string  | String        | 1.0.2 |
      | integer | Integer       | 2     |
      | double  | Double        | 0.1   |
      | boolean | Boolean       | true  |

  Scenario Outline: Returns no metadata
    Given a <type>-flag with key "<key>" and a default value "<default_value>"
    When the flag was evaluated with details
    Then the resolved metadata is empty

    Examples: Flags
      | key          | type    | default_value |
      | boolean-flag | Boolean | true          |
      | integer-flag | Integer | 23            |
      | float-flag   | Float   | 2.3           |
      | string-flag  | String  | value         |
