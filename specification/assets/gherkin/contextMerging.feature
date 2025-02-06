Feature: Context merging precedence

    Background:
        Given a stable provider with retrievable context is registered

    Scenario Outline: A context entry is added to a single level
        Given A context entry with key "key" and value "value" is added to the "<level>" level
        When Some flag was evaluated
        Then The merged context contains an entry with key "key" and value "value"

        Examples:
            | level        |
            | API          |
            | Transaction  |
            | Client       |
            | Invocation   |
            | Before Hooks |

    Scenario: A context entry is added to each level with different keys
        Given A context entry with key "API" and value "API value" is added to the "API" level
        And A context entry with key "Transaction" and value "Transaction value" is added to the "Transaction" level
        And A context entry with key "Client" and value "Client value" is added to the "Client" level
        And A context entry with key "Invocation" and value "Invocation value" is added to the "Invocation" level
        And A context entry with key "Before Hooks" and value "Before Hooks value" is added to the "Before Hooks" level
        When Some flag was evaluated
        Then The merged context contains an entry with key "API" and value "API value"
        And The merged context contains an entry with key "Transaction" and value "Transaction value"
        And The merged context contains an entry with key "Client" and value "Client value"
        And The merged context contains an entry with key "Invocation" and value "Invocation value"
        And The merged context contains an entry with key "Before Hooks" and value "Before Hooks value"

    Scenario Outline: A context entry in one level overwrites values with the same key from preceding levels
        Given A table with levels of increasing precedence
            | API          |
            | Transaction  |
            | Client       |
            | Invocation   |
            | Before Hooks |
        And Context entries for each level from API level down to the "<level>" level with key "key" and value "<level>"
        When Some flag was evaluated
        Then The merged context contains an entry with key "key" and value "<level>"

        Examples:
            | level        |
            | API          |
            | Transaction  |
            | Client       |
            | Invocation   |
            | Before Hooks |
