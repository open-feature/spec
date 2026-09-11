Feature: Provider flag evaluation

  # Verifies that a provider maps backend responses onto typed resolution details correctly.
  #
  # This does NOT test the backend's evaluation logic. Every flag in the canonical set except
  # targeted-flag resolves to its default variant whatever the context, so what is under test is
  # purely the provider's mapping of a backend response to a value, a variant and a reason.
  # targeted-flag carries the one rule, and only to show the context reached the backend.
  #
  # Every success path also asserts that no error message was set (requirement 2.3.2). A
  # provider that reports a value AND an error message is sending two contradictory signals,
  # and an application reading the message will believe the wrong one.
  #
  # Requires the backend to be seeded with the canonical flag set — see flags/canonical-flags.json.

  Background:
    Given a stable provider

  Scenario Outline: Resolve values with reason
    Given a <type>-flag with key "<key>" and a default value "<default>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"
    And the reason should be "<reason>"
    And the error-code should be ""
    And the error message should be empty
    And no exception should have been thrown

    Examples:
      | key          | type    | default | value | reason |
      | boolean-flag | Boolean | false   | true  | STATIC |
      | string-flag  | String  | bye     | hi    | STATIC |
      | integer-flag | Integer | 1       | 10    | STATIC |
      | float-flag   | Float   | 0.1     | 0.5   | STATIC |

  Scenario Outline: A falsy value is a value, not an absence
    # false, 0 and "" are the values most likely to be mistaken for "nothing came back": a
    # `value || default` in JavaScript, a zero-value check in Go, an `if not value` in Python.
    # Each row's default differs from its resolved value, so a provider that falls back on a
    # falsy result returns the wrong value AND the wrong reason, and is caught twice over.
    Given a <type>-flag with key "<key>" and a default value "<default>"
    When the flag was evaluated with details
    Then the resolved details value should be "<value>"
    And the reason should be "STATIC"
    And the error-code should be ""
    And the error message should be empty
    And no exception should have been thrown

    Examples:
      | key               | type    | default  | value |
      | boolean-zero-flag | Boolean | true     | false |
      | integer-zero-flag | Integer | 1        | 0     |
      | string-zero-flag  | String  | fallback |       |

  @variants
  Scenario Outline: The resolved details name the variant
    # Gated, because a variant is optional rather than required. types.md declares the field
    # "variant (string, optional)", and Requirement 2.2.4 is a SHOULD: in normal execution a
    # provider "SHOULD populate the resolution details structure's variant field". The same
    # section goes further and says the value "might only be meaningful in the context of the
    # flag management system associated with the provider".
    #
    # Some systems have no variant concept for a plain flag at all. Their evaluation response
    # carries no such key, so the provider never receives one and no amount of seeding can
    # produce one. Asserting a variant in every scenario failed such a backend ten times over
    # for something that is not a defect and that no provider author can fix — and left nothing
    # to record as a known deviation, because there was no capability to hang one on.
    #
    # A provider whose backend names its variants declares this tag and these rows run. One
    # whose backend does not leaves it undeclared, and they are skipped with that reason rather
    # than passed. Either way the value and reason assertions above are unaffected: they are
    # untagged, and 2.2.3 makes the value a MUST.
    Given a <type>-flag with key "<key>" and a default value "<default>"
    When the flag was evaluated with details
    Then the variant should be "<variant>"
    And the error-code should be ""
    And the error message should be empty
    And no exception should have been thrown

    Examples:
      | key                | type    | default  | variant   |
      | boolean-flag       | Boolean | false    | on        |
      | string-flag        | String  | bye      | greeting  |
      | integer-flag       | Integer | 1        | ten       |
      | float-flag         | Float   | 0.1      | half      |
      | boolean-zero-flag  | Boolean | true     | zero      |
      | integer-zero-flag  | Integer | 1        | zero      |
      | string-zero-flag   | String  | fallback | zero      |
      | large-integer-flag | Integer | 1        | max-int32 |

  Scenario: A large integer resolves without loss of precision
    # 2147483647 is 2^31 - 1, the largest 32-bit signed integer, so every language's integer
    # accessor can ask for it. It is also outside what a 32-bit float represents exactly, so a
    # provider that routes integers through float32 and back returns 2147483648.
    Given a Integer-flag with key "large-integer-flag" and a default value "1"
    When the flag was evaluated with details
    Then the resolved details value should be "2147483647"
    And the reason should be "STATIC"
    And the error-code should be ""
    And no exception should have been thrown

  @large-integers
  Scenario: An integer beyond 32 bits resolves without loss of precision
    # 9007199254740991 is 2^53 - 1: the largest integer JavaScript represents exactly, and
    # comfortably inside a 64-bit integer. Anything that routes the value through a 32-bit
    # integer, or through a 64-bit float and back with rounding, changes it.
    #
    # Tagged, because whether it can be asked for at all is a property of the language's
    # SDK rather than of the provider: Java's integer accessor is a 32-bit Integer, and a
    # provider cannot resolve a value the accessor has no room for. Values above 2^53 - 1 are
    # deliberately not asked for. What a provider must do with a value that does not fit the
    # requested accessor is an open question of the provider contract (open-feature/spec#430).
    Given a Integer-flag with key "huge-integer-flag" and a default value "1"
    When the flag was evaluated with details
    Then the resolved details value should be "9007199254740991"
    And the reason should be "STATIC"
    And the error-code should be ""
    And no exception should have been thrown

  Scenario: An integer flag resolves as an integer
    # Paired with the float scenario below and with the narrowing scenario in errors.feature.
    # Together they pin down that the two numeric types stay distinct rather than both being
    # funnelled through one numeric representation.
    Given a Integer-flag with key "integer-flag" and a default value "1"
    When the flag was evaluated with details
    Then the resolved details value should be "10"
    And the error-code should be ""
    And the error message should be empty
    And no exception should have been thrown

  Scenario: A float flag resolves as a float
    Given a Float-flag with key "float-flag" and a default value "0.1"
    When the flag was evaluated with details
    Then the resolved details value should be "0.5"
    And the error-code should be ""
    And the error message should be empty
    And no exception should have been thrown

  @object
  Scenario: Resolve a structured value
    Given a Object-flag with key "object-flag" and a default value "{}"
    When the flag was evaluated with details
    Then the reason should be "STATIC"
    And the error-code should be ""
    And the error message should be empty
    And no exception should have been thrown
    And the resolved object value should contain
      | key           | type    | value                 |
      | showImages    | Boolean | true                  |
      | title         | String  | Check out these pics! |
      | imagesPerPage | Integer | 100                   |
  Scenario: Supplying an evaluation context does not disturb an untargeted resolution
    # Mandatory, and the only scenario that passes a context to a provider with no targeting
    # involved. Requirement 2.2.1 makes the evaluation context a parameter of every resolve
    # method, but until this scenario existed no scenario supplied one — so a provider that
    # threw on any context, or serialised it into a malformed request, passed the whole suite.
    #
    # string-flag has no targeting rule, so the context cannot change the outcome. What is
    # under test is only that supplying one is harmless.
    #
    # Deliberately asserts the value and the absence of an error rather than the reason.
    # 2.2.3 makes the value a MUST and 2.2.6 forbids an error code in normal execution, while
    # the reason is a SHOULD that 2.2.5 lets a provider populate with "some other string" —
    # and with a context supplied and nothing matching, both "STATIC" and "DEFAULT" are
    # defensible readings.
    Given a String-flag with key "string-flag" and a default value "bye"
    And an evaluation context with targeting key "tck-other-user"
    When the flag was evaluated with details
    Then the resolved details value should be "hi"
    And the error-code should be ""
    And the error message should be empty
    And no exception should have been thrown

  @targeting
  Scenario: A matching evaluation context resolves the targeted variant
    # This is what makes context passthrough observable. Every other flag resolves the same way
    # whatever the context, so a provider that drops the context entirely passes them all. Here
    # a matching context resolves to a different value, so dropping it is caught by the resolved
    # value itself — no echo endpoint on the control API required.
    #
    # targeted-flag's rule is specified by behaviour, not by syntax: resolve "targeted" when the
    # targeting key is exactly "tck-targeted-user", "untargeted" otherwise. Express it however
    # your backend expresses targeting.
    Given a String-flag with key "targeted-flag" and a default value "fallback"
    And an evaluation context with targeting key "tck-targeted-user"
    When the flag was evaluated with details
    Then the resolved details value should be "targeted"
    And the error-code should be ""
    And no exception should have been thrown

  @targeting
  Scenario: A non-matching evaluation context resolves the default variant
    # Paired with the scenario above, and the reason it is not enough on its own: a provider
    # that always returned the targeted value would pass that one. This is what pins down that
    # the rule was evaluated rather than the targeted variant simply being served.
    Given a String-flag with key "targeted-flag" and a default value "fallback"
    And an evaluation context with targeting key "tck-other-user"
    When the flag was evaluated with details
    Then the resolved details value should be "untargeted"
    And the error-code should be ""
    And no exception should have been thrown

  @targeting
  Scenario: No evaluation context resolves the default variant
    # A targeting rule that cannot match must not error. A provider that requires a targeting
    # key, or that fails to evaluate a rule when the context is absent, is caught here.
    Given a String-flag with key "targeted-flag" and a default value "fallback"
    When the flag was evaluated with details
    Then the resolved details value should be "untargeted"
    And the error-code should be ""
    And no exception should have been thrown
