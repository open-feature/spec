Feature: Events

# This test suite contains scenarios to test the Events API.

  Background:
    Given a provider which supports events and requires initialization

  # initialization events
  Scenario: PROVIDER_READY is emitted
    When a PROVIDER_READY handler is attached
    And the provider is set and successully initialized
    Then the PROVIDER_READY handler must run

  Scenario: PROVIDER_ERROR is emitted
    When a PROVIDER_ERROR handler is attached
    And the provider is set and fails to initialize
    Then the PROVIDER_ERROR handler must run

  # provider-initiated events
  Scenario: PROVIDER_CONFIGURATION_CHANGED is emitted
    When a PROVIDER_CONFIGURATION_CHANGED handler is attached
    And a flag with key "changing-flag" is modified
    Then the PROVIDER_CONFIGURATION_CHANGED handler must run
    And the event details must indicate "changing-flag" was altered