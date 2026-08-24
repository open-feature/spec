@lifecycle
Feature: Provider lifecycle

  # Verifies the two terminal outcomes of provider initialisation: reaching READY against a
  # healthy backend, and settling into ERROR against one that cannot be reached.
  #
  # Gated by @lifecycle rather than @events, and the distinction is load-bearing. Every SDK
  # synthesises PROVIDER_READY for a provider that has no initialisation step, so a provider
  # without a lifecycle passes the readiness scenario below without demonstrating anything --
  # a NoOpProvider passes it identically. @lifecycle asserts that the provider actually reaches
  # its backend during initialisation and that the outcome is observable; a provider that merely
  # emits events does not necessarily do that.
  #
  # The failure case matters more than it looks. A provider that blocks forever, or throws out
  # of provider registration, takes the host application down with it — so the requirement is
  # not merely that initialisation fails, but that it fails observably and promptly.

  Scenario: A provider reaching its backend becomes ready
    Given a stable provider
    And a ready event handler
    Then the ready event handler should have been executed
    And the client should be in ready state

  @unavailable
  Scenario: A provider that cannot reach its backend reports an error
    Given a unavailable provider
    And a error event handler
    Then the error event handler should have been executed within 10000ms
    And the client should be in error state

  @unavailable
  Scenario: A provider that cannot reach its backend still returns code defaults
    Given a unavailable provider
    And a error event handler
    And a Boolean-flag with key "boolean-flag" and a default value "false"
    Then the error event handler should have been executed within 10000ms
    When the flag was evaluated with details
    Then the resolved details value should be "false"
    And the reason should be "ERROR"
    And no exception should have been thrown
