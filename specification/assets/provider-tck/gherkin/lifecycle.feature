@lifecycle
Feature: Provider lifecycle

  # Verifies the two terminal outcomes of provider initialisation: reaching READY against a
  # healthy backend, and settling into ERROR against one that cannot be reached. And the other
  # end of the lifecycle: that shutdown releases what initialisation acquired, can be repeated,
  # and does not hang when the backend is gone.
  #
  # Gated by @lifecycle rather than @events, and the distinction is load-bearing. Every SDK
  # synthesises PROVIDER_READY for a provider that has no initialisation step, so a provider
  # without a lifecycle passes the readiness scenario below without demonstrating anything --
  # a NoOpProvider passes it identically. @lifecycle asserts that the provider actually reaches
  # its backend during initialisation and that the outcome is observable; a provider that merely
  # emits events does not necessarily do that.
  #
  # The failure case matters more than it looks. A provider that blocks forever, or throws out
  # of provider registration, takes the host application down with it -- so the requirement is
  # not merely that initialisation fails, but that it fails observably and promptly.
  #
  # The shutdown steps call the provider's own shutdown and initialize functions directly, not
  # the SDK's. The SDK shuts a provider down when it is replaced, but wrapping that in a scenario
  # would test the SDK's bookkeeping as much as the provider's, and Appendix B already does that.

  Scenario: A provider that successfully initializes becomes ready
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

  Scenario: Shutting down a provider twice has no further effect
    # Requirement 2.5.3. Double-close is the classic shutdown bug: the second call finds a
    # closed channel, a null connection or a disposed client, and throws from a code path the
    # application runs during its own shutdown -- where an exception is least welcome.
    Given a stable provider
    When the provider is shut down
    And the provider is shut down
    Then no exception should have been thrown

  @reinitialization
  Scenario: A provider that was shut down can be initialized again
    # Requirement 2.5.2 says a provider SHOULD revert to its uninitialized state after shutdown,
    # and its supporting text says "some providers MAY allow reinitialization from this state".
    # Reuse is therefore permitted, not required, and this scenario is gated accordingly: a
    # provider that shuts down by discarding its client and never recreating it is making a
    # choice the specification allows, not exhibiting a defect.
    #
    # What the tag buys is the other direction. A provider that does claim to be reusable has
    # somewhere to be held to it, because "shutdown() releases the client and initialize()
    # returns early because an initialised flag was never cleared" is easy to write and leaves
    # the provider evaluating against a closed connection rather than failing outright.
    #
    # Reverting the state itself is not separately observable: a provider that reverts but
    # refuses reuse presents exactly as one that did neither. So this is the only assertion the
    # requirement admits, and it only applies where reuse is offered.
    Given a stable provider
    And a Boolean-flag with key "boolean-flag" and a default value "false"
    When the provider is shut down
    And the provider is initialized again
    And the flag was evaluated with details
    Then the resolved details value should be "true"
    And the reason should be "STATIC"
    And the error-code should be ""
    And no exception should have been thrown

  @unavailable
  Scenario: Shutting down a provider that cannot reach its backend completes promptly
    # A shutdown that waits for a graceful close of a connection that will never answer hangs
    # the host application's own shutdown. The bound is generous; what is being asserted is
    # that shutdown returns at all rather than blocking on the backend.
    Given a unavailable provider
    And a error event handler
    Then the error event handler should have been executed within 10000ms
    When the provider is shut down
    Then the shutdown should have completed within 10000ms
    And no exception should have been thrown
