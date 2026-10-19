@standard-reasons
Feature: Provider resolution reasons

  # Verifies that a provider reports the standard resolution reasons, with the meanings Appendix F
  # gives them.
  #
  # THE WHOLE FILE IS GATED, and the gate is a claim rather than an excuse. Requirement 2.2.5 is a
  # SHOULD, and it goes further than the other SHOULDs: a provider may populate `reason` with one of
  # the listed values "or some other string indicating the semantic reason for the returned flag
  # value". A provider whose backend reports vendor-specific reasons is therefore conformant, and
  # asserting an exact reason against it would fail it for something the specification permits.
  #
  # So `@standard-reasons` is a provider saying "I use the standard vocabulary, with the standard
  # meanings" — and this file is what checks that claim. A provider that does not say it leaves these
  # scenarios skipped with their reason and loses nothing; its values and error codes are still
  # asserted everywhere else, because those rest on MUSTs. The declaration is what a consumer reads
  # when it wants to build telemetry, dashboards or debugging on `reason`: the claim was verified,
  # not assumed.
  #
  # No other scenario in this suite asserts a reason. That is deliberate — an earlier revision
  # asserted one in thirteen places across three files, which narrowed a SHOULD into a MUST for every
  # adopter, and bought very little: every canonical flag resolves to a value distinct from the
  # caller's default, so a provider that silently falls back is already caught by the value.
  #
  # TAGS COMPOSE. A scenario carrying `@targeting` or `@disabled-flags` needs that capability
  # declared as well, because the reason cannot be observed without the behaviour that produces it.
  #
  # Two reasons are deliberately absent. CACHED belongs behind the reserved `@caching` tag and needs
  # a repeat evaluation, which no scenario in this suite performs without a configuration change in
  # between — see the caching note in Appendix F. STALE is reported during an outage, and what a
  # provider serves while stale is itself uncovered, so there is nothing to attach it to yet.
  #
  # Requires the backend to be seeded with the canonical flag set — see flags/canonical-flags.json.

  Background:
    Given a stable provider

  Scenario Outline: A flag with no targeting rules resolves statically
    # This is the assertion the specification leaves genuinely open, and the reason this capability
    # has to define its terms rather than merely name them. `types.md` types DEFAULT as "no dynamic
    # evaluation occurred OR dynamic evaluation yielded no result", which a rule-less flag satisfies
    # as readily as STATIC does. Appendix F picks STATIC for this capability — see its reason
    # mapping — and a provider that answers DEFAULT here is not thereby defective, it simply does
    # not use the standard meanings and should not declare the tag.
    Given a <type>-flag with key "<key>" and a default value "<default>"
    When the flag was evaluated with details
    Then the reason should be "STATIC"
    And the error-code should be ""
    And no exception should have been thrown

    Examples:
      | key          | type    | default |
      | boolean-flag | Boolean | false   |
      | string-flag  | String  | bye     |
      | integer-flag | Integer | 1       |
      | float-flag   | Float   | 0.1     |

  # THE TWO ERROR SCENARIOS BELOW ASSERT AGREEMENT, not authorship, and the distinction is worth
  # stating because it is the one place this file's subject is blurred.
  #
  # Every other scenario here rests on [Requirement 1.4.7](../../../sections/01-flag-evaluation.md),
  # which makes the SDK propagate the provider's reason — but only "in cases of normal execution".
  # Abnormal execution is 1.4.9, and that is a SHOULD on the *SDK* to "indicate an error"; nothing
  # requires the provider's reason to survive. So a passing ERROR scenario does not establish that
  # the provider set the reason, only that whatever reached the application is consistent.
  #
  # They are still worth running. The error code alone is already asserted in errors.feature, on a
  # MUST, for every provider; the reason alone could be written by the SDK. Asserting the pair is
  # the part neither field can satisfy on its own, and an evaluation that reports FLAG_NOT_FOUND
  # with reason STATIC is incoherent whoever wrote it.

  Scenario: An unknown flag reports an error
    Given a String-flag with key "missing-flag" and a default value "fallback"
    When the flag was evaluated with details
    Then the reason should be "ERROR"
    And the error-code should be "FLAG_NOT_FOUND"
    And no exception should have been thrown

  Scenario: A type mismatch reports an error
    Given a String-flag with key "boolean-flag" and a default value "fallback"
    When the flag was evaluated with details
    Then the reason should be "ERROR"
    And the error-code should be "TYPE_MISMATCH"
    And no exception should have been thrown

  @targeting
  Scenario: A matching targeting rule reports a targeting match
    # Needs @targeting as well: a provider with no targeting has no rule to match, so there is no
    # TARGETING_MATCH for it to report and the scenario would fail it for an absence rather than a
    # defect.
    Given a String-flag with key "targeting-key-flag" and a default value "fallback"
    And a context containing a targeting key with value "5c3d8535-f81a-4478-a6d3-afaa4d51199e"
    When the flag was evaluated with details
    Then the reason should be "TARGETING_MATCH"
    And the error-code should be ""
    And no exception should have been thrown

  @targeting
  Scenario: A targeting rule that does not match reports the default
    # The other half, and the one that distinguishes the two reasons rather than merely observing
    # one of them. A provider that reports TARGETING_MATCH whenever a rule exists, matched or not,
    # passes the scenario above and fails this one.
    Given a String-flag with key "targeting-key-flag" and a default value "fallback"
    And a context containing a targeting key with value "f20bd32d-703b-48b6-bc8e-79d53c85134a"
    When the flag was evaluated with details
    Then the reason should be "DEFAULT"
    And the error-code should be ""
    And no exception should have been thrown

  @disabled-flags
  Scenario: A disabled flag reports that it is disabled
    # Needs @disabled-flags as well, for the same reason: a backend that cannot distinguish a
    # disabled flag produces no DISABLED signal for the provider to pass on. The @disabled-flags
    # scenarios themselves assert only the value, because pinning the reason there would have
    # narrowed 2.2.5 for every adopter — this is where that narrowing is opted into instead.
    Given a Boolean-flag with key "disabled-boolean-flag" and a default value "false"
    When the flag was evaluated with details
    Then the reason should be "DISABLED"
    And the error-code should be ""
    And no exception should have been thrown
