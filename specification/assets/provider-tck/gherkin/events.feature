@events
Feature: Provider events

  # Verifies that a provider notices changes in its backend and both signals them and acts on
  # them. Signalling alone is not enough: a configuration-change event that is not followed by
  # a changed evaluation result is a lie, so each scenario asserts the event AND the behaviour.
  #
  # Outages here are simulated inside the running stack via the control API. No container is
  # ever stopped or restarted — see the invariant in openapi/control-api.yaml.

  Background:
    Given a stable provider

  @configuration-change
  Scenario: A configuration change is signalled and applied
    Given a String-flag with key "changing-flag" and a default value "unset"
    And a change event handler
    When the flag was evaluated with details
    And the resolved value is remembered
    And the flag was modified
    Then the change event handler should have been executed
    And the flag should be part of the event payload
    When the flag was evaluated with details
    Then the resolved details value should have changed
    And no exception should have been thrown

  @stale
  Scenario: Losing the backend makes the provider stale, regaining it makes it ready again
    Given a ready event handler
    And a stale event handler
    When a ready event was fired
    And the connection is lost
    Then the stale event handler should have been executed
    And the client should be in stale state
    When the connection is restored
    Then the ready event handler should have been executed
    And the client should be in ready state

  # Deliberately NOT covered here: whether a stale provider keeps serving last-known values
  # during the outage. That is caching behaviour, which depends on whether the provider holds a
  # local copy of the ruleset, and it belongs behind the @caching capability once those
  # scenarios are written. See the "Known gaps" section of the README.
