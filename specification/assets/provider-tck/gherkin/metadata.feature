Feature: Provider metadata

  # Verifies that a provider identifies itself (requirement 2.1.1). This looks too small to
  # test, and was left untested for exactly that reason -- until a conformance report keyed on
  # the provider's metadata name made an empty name into a report nobody can attribute.

  Scenario: A provider identifies itself by name
    Given a stable provider
    Then the provider metadata name should not be empty
