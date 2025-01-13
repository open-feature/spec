@Metadata
Feature: Metadata

  Background:
    Given a provider is registered

  Scenario: Returns metadata
    Given a Boolean-flag with key "metadata-flag" and a default value "true"
    When the flag was evaluated with details
    Then the resolved metadata value "string" with type "String" should be "1.0.2"
    And the resolved metadata value "integer" with type "Integer" should be "2"
    And the resolved metadata value "double" with type "Double" should be "0.1"
    And the resolved metadata value "boolean" with type "Boolean" should be "true"

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
