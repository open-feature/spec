Feature: Tracking

# This test suite contains scenarios to test the tracking API.

  Background:
    Given a provider is registered

  Scenario Outline: Invalid event names
    When an event was tracked with tracking event name <event_name>
    Then nothing should have been tracked
    And the tracking operation shall error
    Examples: Basic
      | event_name |
      | ""         |
      | "NULL"     |

  Scenario Outline: Provider's track functionality is called
    When an event was tracked with tracking event name <event_name>
    Then the tracking provider should have been called with event name <event_name>
    Examples: Basic
      | event_name   |
      | "the-event" |
