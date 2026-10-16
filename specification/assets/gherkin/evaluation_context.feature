@evaluation-context
Feature: Evaluation Context and Merging
  # This test suite covers evaluation context field requirements and merging precedence
  # as defined in section 03-evaluation-context.md

  Background:
    Given a stable provider with retrievable context is registered

  # Spec 3.2.3: Context merging precedence - single level context
  @context-merging @spec-3.2.3
  Scenario Outline: A context entry is added to a single level
    Given A context entry with key "key" and value "value" of type "string" is added to the "<level>" level
    When Some flag was evaluated
    Then The merged context contains an entry with key "key" and value "value" of type "string"

    @transaction
    Examples:
      | level       |
      | API         |
      | Transaction |
      | Client      |
      | Invocation  |

    @hooks
    Examples:
      | level        |
      | API          |
      | Client       |
      | Invocation   |
      | Before Hooks |

    @hooks @transaction
    Examples:
      | level        |
      | API          |
      | Transaction  |
      | Client       |
      | Invocation   |
      | Before Hooks |

  # Spec 3.2.3: Context merging order - transaction context with different keys
  @transaction @context-merging @spec-3.2.3
  Scenario: For a transaction, a context entry of type "string" is added to each level with different keys
    Given A context entry with key "API" and value "API value" of type "string" is added to the "API" level
    And A context entry with key "Transaction" and value "Transaction value" of type "string" is added to the "Transaction" level
    And A context entry with key "Client" and value "Client value" of type "string" is added to the "Client" level
    And A context entry with key "Invocation" and value "Invocation value" of type "string" is added to the "Invocation" level
    When Some flag was evaluated
    Then The merged context contains an entry with key "API" and value "API value" of type "string"
    And The merged context contains an entry with key "Transaction" and value "Transaction value" of type "string"
    And The merged context contains an entry with key "Client" and value "Client value" of type "string"
    And The merged context contains an entry with key "Invocation" and value "Invocation value" of type "string"

  # Spec 3.2.3: Context merging order - hook context with different keys
  @hooks @context-merging @spec-3.2.3
  Scenario: For a hook, a context entry of type "string" is added to each level with different keys
    Given A context entry with key "API" and value "API value" of type "string" is added to the "API" level
    And A context entry with key "Client" and value "Client value" of type "string" is added to the "Client" level
    And A context entry with key "Invocation" and value "Invocation value" of type "string" is added to the "Invocation" level
    And A context entry with key "Before Hooks" and value "Before Hooks value" of type "string" is added to the "Before Hooks" level
    When Some flag was evaluated
    Then The merged context contains an entry with key "API" and value "API value" of type "string"
    And The merged context contains an entry with key "Client" and value "Client value" of type "string"
    And The merged context contains an entry with key "Invocation" and value "Invocation value" of type "string"
    And The merged context contains an entry with key "Before Hooks" and value "Before Hooks value" of type "string"

  # Spec 3.2.3: Context merging order - transaction and hook context with different keys
  @hooks @transaction @context-merging @spec-3.2.3
  Scenario: For a transaction and a hook, a context entry of type "string" is added to each level with different keys
    Given A context entry with key "API" and value "API value" of type "string" is added to the "API" level
    And A context entry with key "Transaction" and value "Transaction value" of type "string" is added to the "Transaction" level
    And A context entry with key "Client" and value "Client value" of type "string" is added to the "Client" level
    And A context entry with key "Invocation" and value "Invocation value" of type "string" is added to the "Invocation" level
    And A context entry with key "Before Hooks" and value "Before Hooks value" of type "string" is added to the "Before Hooks" level
    When Some flag was evaluated
    Then The merged context contains an entry with key "API" and value "API value" of type "string"
    And The merged context contains an entry with key "Transaction" and value "Transaction value" of type "string"
    And The merged context contains an entry with key "Client" and value "Client value" of type "string"
    And The merged context contains an entry with key "Invocation" and value "Invocation value" of type "string"
    And The merged context contains an entry with key "Before Hooks" and value "Before Hooks value" of type "string"

  # Spec 3.2.3: Context merging precedence - transaction context overwrites
  @transaction @context-precedence @spec-3.2.3
  Scenario Outline: For a transaction, a context entry in one level overwrites values with the same key from preceding levels
    Given A table with levels of increasing precedence
      | API         |
      | Transaction |
      | Client      |
      | Invocation  |
    And Context entries for each level from API level down to the "<level>" level, with key "key" and value "<level>" of type "string"
    When Some flag was evaluated
    Then The merged context contains an entry with key "key" and value "<level>" of type "string"

    Examples:
      | level       |
      | API         |
      | Transaction |
      | Client      |
      | Invocation  |

  # Spec 3.2.3: Context merging precedence - hook context overwrites
  @hooks @context-precedence @spec-3.2.3
  Scenario Outline: For a hook, a context entry in one level overwrites values with the same key from preceding levels
    Given A table with levels of increasing precedence
      | API          |
      | Client       |
      | Invocation   |
      | Before Hooks |
    And Context entries for each level from API level down to the "<level>" level, with key "key" and value "<level>" of type "string"
    When Some flag was evaluated
    Then The merged context contains an entry with key "key" and value "<level>" of type "string"

    Examples:
      | level        |
      | API          |
      | Client       |
      | Invocation   |
      | Before Hooks |

  # Spec 3.2.3: Context merging precedence - transaction and hook context overwrites
  @hooks @transaction @context-precedence @spec-3.2.3
  Scenario Outline: For a transaction and a hook, context entry in one level overwrites values with the same key from preceding levels
    Given A table with levels of increasing precedence
      | API          |
      | Transaction  |
      | Client       |
      | Invocation   |
      | Before Hooks |
    And Context entries for each level from API level down to the "<level>" level, with key "key" and value "<level>" of type "string"
    When Some flag was evaluated
    Then The merged context contains an entry with key "key" and value "<level>" of type "string"

    Examples:
      | level        |
      | API          |
      | Transaction  |
      | Client       |
      | Invocation   |
      | Before Hooks |

  # Spec 3.1.1: Evaluation context must define optional targeting key field
  @context-fields @targeting-key @spec-3.1.1
  Scenario: Evaluation context targeting key field
    Given A context entry with key "targeting_key" and value "user-123" of type "string" is added to the "Invocation" level
    When Some flag was evaluated
    Then The merged context contains an entry with key "targeting_key" and value "user-123" of type "string"

  @context-fields @targeting-key @spec-3.1.1
  Scenario: Evaluation context without targeting key
    When Some flag was evaluated
    Then the evaluation context should allow missing "targeting_key" field

  # Spec 3.1.2: Evaluation context must support custom fields with specified types
  @context-fields @custom-fields @spec-3.1.2
  Scenario Outline: Evaluation context custom field types
    Given A context entry with key "<key>" and value "<value>" of type "<type>" is added to the "Invocation" level
    When Some flag was evaluated
    Then The merged context contains an entry with key "<key>" and value "<value>" of type "<type>"

    Examples: Supported custom field types
      | key          | type      | value                           |
      | user_active  | boolean   | true                           |
      | user_email   | string    | user@example.com               |
      | user_age     | integer   | 25                             |

  # Spec 3.1.3: Evaluation context must support fetching fields by key and all key-value pairs
  @context-fields @field-access @spec-3.1.3
  Scenario: Evaluation context field access methods
    Given A context entry with key "user_name" and value "John Doe" of type "string" is added to the "Invocation" level
    And A context entry with key "user_age" and value "30" of type "integer" is added to the "Invocation" level
    And A context entry with key "is_premium" and value "true" of type "boolean" is added to the "Invocation" level
    When Some flag was evaluated
    Then The merged context contains an entry with key "user_name" and value "John Doe" of type "string"
    And The merged context contains an entry with key "user_age" and value "30" of type "integer"
    And The merged context contains an entry with key "is_premium" and value "true" of type "boolean"

  # Spec 3.1.4: Evaluation context fields must have unique keys
  @context-fields @unique-keys @spec-3.1.4
  Scenario: Evaluation context field key uniqueness
    Given A context entry with key "user_id" and value "123" of type "string" is added to the "Client" level
    And A context entry with key "user_id" and value "456" of type "string" is added to the "Invocation" level
    When Some flag was evaluated
    Then The merged context contains an entry with key "user_id" and value "456" of type "string"

  # Context Paradigm & Propagation Requirements - IMPLICITLY COVERED
  # The following specification requirements are implicitly tested by the context merging scenarios above:
  #
  # Context Paradigms (3.2.1.1, 3.2.2.1-2.4, 3.2.4.1-4.2):
  # - 3.2.1.1: Dynamic context methods proven by successful API/Client/Invocation context merging
  # - 3.2.2.1-2.2: Static context paradigm is an architectural decision, not behavioral requirement  
  # - 3.2.2.3-2.4: Domain-specific context management is provider-level functionality
  # - 3.2.4.1-4.2: Context change notifications are provider lifecycle concerns
  #
  # Context Propagation (3.3.1.1, 3.3.1.2.1-2.3, 3.3.2.1):
  # - 3.3.1.1: Transaction context propagator management is API availability, not behavior
  # - 3.3.1.2.1: Transaction context setting/retrieval proven by @transaction merging tests
  # - 3.3.1.2.2-2.3: Propagator method availability is architectural validation
  # - 3.3.2.1: Static paradigm restrictions are design decisions, not behavioral tests
  #
  # No additional behavioral tests needed - the merging scenarios validate the core functionality.
