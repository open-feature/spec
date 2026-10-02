Feature: Provider error handling

  # Every scenario here asserts the same three-part contract, because all three parts matter and
  # providers routinely get one of them wrong:
  #
  #   1. the code default is returned — an application must keep working,
  #   2. the correct error code is reported — an application must be able to tell what went wrong,
  #   3. nothing is thrown — an unhandled exception from a flag evaluation is never acceptable.
  #
  # Requires the backend to be seeded with the canonical flag set — see flags/canonical-flags.json.

  Background:
    Given a stable provider

  Scenario Outline: Requesting the wrong type returns the code default
    # The requests no representation can satisfy honestly. Two questions are held out of this
    # matrix because they have defensible answers rather than obvious ones: whether a number fits
    # a narrower accessor (@numeric-coercion) and whether any flag may be returned through the
    # string accessor (@string-typing). What is left is the set no backend can satisfy -- "hello"
    # is not a boolean, and true is not a number, however the backend stores them.
    Given a <requested>-flag with key "<key>" and a default value "<default>"
    When the flag was evaluated with details
    Then the resolved details value should be "<default>"
    And the error-code should be "TYPE_MISMATCH"
    And no exception should have been thrown

    Examples: a string flag requested as something else
      | key         | requested | default  |
      | string-flag | Boolean   | false    |
      | string-flag | Integer   | 1        |
      | string-flag | Float     | 0.1      |
      | wrong-flag  | Boolean   | false    |

    Examples: a boolean flag requested as something else
      | key          | requested | default  |
      | boolean-flag | Integer   | 1        |
      | boolean-flag | Float     | 0.1      |

    Examples: a numeric flag requested as a non-numeric type
      | key          | requested | default  |
      | integer-flag | Boolean   | false    |
      | float-flag   | Boolean   | false    |

  @object
  Scenario Outline: Requesting a structured flag as a scalar returns the code default
    Given a <requested>-flag with key "object-flag" and a default value "<default>"
    When the flag was evaluated with details
    Then the resolved details value should be "<default>"
    And the error-code should be "TYPE_MISMATCH"
    And no exception should have been thrown

    Examples:
      | requested | default  |
      | Boolean   | false    |
      | Integer   | 1        |
      | Float     | 0.1      |

  @numeric-coercion
  Scenario: A float flag is not silently narrowed to an integer
    # 'float-flag' resolves to 0.5. Narrowing that to an integer would lose information
    # silently, so it must be reported as a type mismatch rather than rounded.
    #
    # This is the lossy half of the coercion contract; the two scenarios that follow are the
    # lossless half. A provider declaring @numeric-coercion must satisfy all three. Rejecting
    # 0.5 is easy to get right by rejecting every float, and the lossless scenarios are what
    # stop that shortcut from passing.
    Given a Integer-flag with key "float-flag" and a default value "1"
    When the flag was evaluated with details
    Then the resolved details value should be "1"
    And the error-code should be "TYPE_MISMATCH"
    And no exception should have been thrown

  @numeric-coercion
  Scenario: An integral float requested as an integer is coerced without loss
    # 'integral-float-flag' resolves to 10.0. Nothing is lost by returning it as the integer
    # 10, so the coercion rule permits it and a provider declaring the tag must perform it.
    Given a Integer-flag with key "integral-float-flag" and a default value "1"
    When the flag was evaluated with details
    Then the resolved details value should be "10"
    And the error-code should be ""
    And no exception should have been thrown

  @numeric-coercion
  Scenario: An integer requested as a float is widened without loss
    # The other direction. 'integer-flag' resolves to 10; every integer this suite asks for
    # is exactly representable as a float, so a provider declaring the tag must widen it.
    Given a Float-flag with key "integer-flag" and a default value "0.1"
    When the flag was evaluated with details
    Then the resolved details value should be "10"
    And the error-code should be ""
    And no exception should have been thrown

  @string-typing
  Scenario Outline: A non-string flag is not returned as its string representation
    # Every value has a string representation, so a backend that stores flag values as strings
    # satisfies the string accessor for every flag and has no mismatch to report. Its flags are
    # strings, and Requirement 2.2.3 asks it for the resolved flag value, which it returned.
    # Whether that is wrong is not something this suite can assert -- see the appendix.
    #
    # These two rows are the ones a partially typed backend can still answer: a boolean and an
    # integer are types such a store records natively. The float and structured cases are held
    # separately behind @fully-typed-values, because a backend can lack a type for those while
    # having one for these -- and one tag covering both would report a provider that fails these
    # as merely untyped.
    Given a String-flag with key "<key>" and a default value "fallback"
    When the flag was evaluated with details
    Then the resolved details value should be "fallback"
    And the error-code should be "TYPE_MISMATCH"
    And no exception should have been thrown

    Examples:
      | key          |
      | boolean-flag |
      | integer-flag |

  @string-typing @fully-typed-values
  Scenario: A float flag is not returned as its string representation
    # Held apart from the two rows above because a store can record booleans and integers
    # natively and still keep floats as text, which is what @fully-typed-values asks about.
    Given a String-flag with key "float-flag" and a default value "fallback"
    When the flag was evaluated with details
    Then the resolved details value should be "fallback"
    And the error-code should be "TYPE_MISMATCH"
    And no exception should have been thrown

  @object @string-typing @fully-typed-values
  Scenario: A structured flag is not returned as its JSON text
    # The same property one type further out. Three tags: a provider with no structured values
    # cannot be asked at all (@object), and a store that keeps structures as text has nothing
    # to report a mismatch about (@fully-typed-values).
    Given a String-flag with key "object-flag" and a default value "fallback"
    When the flag was evaluated with details
    Then the resolved details value should be "fallback"
    And the error-code should be "TYPE_MISMATCH"
    And no exception should have been thrown

  Scenario: An unknown flag key returns the code default
    # 'missing-flag' is deliberately absent from the canonical flag set.
    Given a String-flag with key "missing-flag" and a default value "fallback"
    When the flag was evaluated with details
    Then the resolved details value should be "fallback"
    And the error-code should be "FLAG_NOT_FOUND"
    And no exception should have been thrown
