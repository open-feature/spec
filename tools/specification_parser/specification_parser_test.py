from unittest import TestCase, skip, main
from os.path import abspath, curdir, join
import re

from specification_parser import (
    find_markdown_file_paths,
    parse,
    parsed_content_to_heirarchy,
    gen_node
)


content_finder = re.compile(r'\s*(?P<level>#+)(?P<headline>[^\n]+)(?P<rest>[^#]*)', re.MULTILINE)
class NewerTestParser(TestCase):
    def test_parses_content(self):
        # parsed_content = [('#', ' Hooks', '\n\n'), ('##', ' Overview', '\n\nHooks are a mechanism whereby application developers can add arbitrary behavior\nto flag evaluation. They operate similarly to middleware in many web frameworks.\n\n'), ('###', ' Definitions', '\n\n**Hook**: Application author/integrator-supplied logic that is called by the OpenFeature framework at a specific stage.\n**Stage**: An explicit portion of the flag evaluation lifecycle. e.g. `before` being "before the evaluation is run.\n**Invocation**: A single call to evaluate a flag. `client.getBooleanValue(..)` is an invocation.\n**API**: The global API singleton.\n\n'), ('###', ' Hook context', '\n\nHook context exists to provide hooks with information about the invocation.\n\n'), ('######', ' Requirement 1.1', '\n\n> Hook context **MUST** provide: the flag key, evaluation context, default value and a list of  executed hooks by stage.\n\n\n'), ('#####', ' Condition 1.2', '\n\n> If the language type system differentiates between strings, numbers, booleans, and structures.\n\n'), ('######', ' Condition 1.2.1', '\n\n> Condition: You **MUST** provide `flag type`.\n\n\n'), ('#####', ' Requirement 1.2', '\n\n> Hook context **SHOULD** provide: provider, client\n\n\n'), ('#####', ' Requirement 1.3', '\n\n> flag key, flag type, default value properties **MUST** be immutable. If the language does not support immutability, the hook **MUST NOT** modify these properties.\n\n'), ('#####', ' Requirement 1.4', '\n\n> The evaluation context **MUST** be mutable only within the `before` hook.\n\n'), ('###', ' HookHints', '\n\n'), ('#####', ' Requirement 2.1', '\n\n> HookHints **MUST** be a map of objects.\n\n\n'), ('#####', ' Condition 2.2', '\n\n> The implementation language supports a mechanism for marking data as immutable.\n\n'), ('######', ' 2.2.1', '\n\n> Condition: HookHints **MUST** be immutable.\n\n\n'), ('###', ' Hook creation and parameters', '\n\n\n'), ('#####', ' Requirement 3.1', '\n\n> Hooks **MUST** specify at least one stage.\n\n'), ('#####', ' Requirement 3.2', '\n\n> The `before` stage **MUST** run before flag evaluation occurs. It accepts a `hook context` (required) and `state` (optional) as parameters and returns either a `HookContext` or nothing.\n\n```\nHookContext|void before(HookContext, HookHints)\n```\n\n'), ('#####', ' Requirement 3.3', '\n\n> The `after` stage **MUST** run after flag evaluation occurs. It accepts a `hook context` (required), `flag evaluation details` (required) and `HookHints` (optional). It has no return value.\n\n'), ('#####', ' Requirement 3.4', '\n\n> The `error` hook **MUST** run when errors are encountered in the `before` stage, the `after` stage or during flag evaluation. It accepts `hook context` (required), `exception` for what went wrong (required), and `HookHints` (optional). It has no return value.\n\n'), ('#####', ' Requirement 3.5', '\n\n> The `finally` hook **MUST** run after the `before`, `after`, and `error` stages. It accepts a `hook context` (required) and `HookHints` (optional). There is no return value.\n\n'), ('#####', ' Condition 3.6', '\n\n> `finally` is a reserved word in the language.\n\n'), ('######', ' 3.6.1', '\n\n> Condition: If `finally` is a reserved word in the language, `finallyAfter` **SHOULD** be used.\n\n'), ('###', ' Hook registration & ordering', '\n\n'), ('#####', ' Requirement 4.1', "\n\n> The API, Client and invocation **MUST** have a method for registering hooks which accepts `flag evaluation options`\n\n```js\nOpenFeature.addHooks(new Hook1());\n\n//...\n\nClient client = OpenFeature.getClient();\nclient.addHooks(new Hook2());\n`\n//...\n\nclient.getValue('my-flag', 'defaultValue', new Hook3());\n```\n\n"), ('#####', ' Requirement 4.2', '\n\n> Hooks **MUST** be evaluated in the following order:\n> - before: API, Client, Invocation\n> - after: Invocation, Client, API\n> - error (if applicable): Invocation, Client, API\n> - finally: Invocation, Client, API> If an error occurs in the `finally` hook, it **MUST NOT** trigger the `error` hook.\n\n'), ('#####', ' Requirement 4.3', '\n\n> If an error occurs in the `before` or `after` hooks, the `error` hooks **MUST** be invoked.\n\n'), ('#####', ' Requirement 4.4', '\n\n> If an error occurs during the evaluation of `before` or `after` hooks, any remaining hooks in the `before` or `after` stages **MUST NOT** be invoked.\n\n'), ('#####', ' Requirement 4.5', '\n\n> If an error is encountered in the error stage, it **MUST NOT** be returned to the user.\n\n\n'), ('###', ' [Flag evaluation options](../types.md#evaluation-options)', "\n\nUsage might looks something like:\n\n```python\nval = client.get_boolean_value('my-key', False, evaluation_options={\n    'hooks': new MyHook(),\n    'hook_hints': {'side-item': 'onion rings'}\n})\n```\n\n"), ('#####', ' Requirement 5.1', '\n\n> `Flag evalution options` **MUST** contain a list of hooks to evaluate.\n\n'), ('#####', ' Requirement 5.2', '\n\n> `Flag evaluation options` **MAY** contain `HookHints`, a map of data to be provided to hook invocations.\n\n'), ('#####', ' Requirement 5.3', '\n\n> `HookHints` **MUST** be passed to each hook through a parameter. It is merged into the object in the precedence order API -> Client -> Invocation (last wins).\n\n```python\nhook_hints = {}\nfor source in [API, Client, Invocation]:\n  for key, value in source:\n    hook-hints[key] = value\n```\n\n'), ('#####', ' Requirement 5.4', '\n\n> The hook **MUST NOT** alter the `HookHints` object.\n\n'), ('###', ' Hook evaluation', '\n\n'), ('#####', ' Requirement 6.1', '\n\n> `HookHints` **MUST** passed between each hook.\n')]
        content = '''
        # test
        content
        ## foo
        more content
        # another outer headline
        '''
        parsed_content = content_finder.findall(content)
        self.assertEqual(None, parsed_content_to_heirarchy(parsed_content))

    def test_parses_content__with_keywords__no_title(self):
        # parsed_content = [('#', ' Hooks', '\n\n'), ('##', ' Overview', '\n\nHooks are a mechanism whereby application developers can add arbitrary behavior\nto flag evaluation. They operate similarly to middleware in many web frameworks.\n\n'), ('###', ' Definitions', '\n\n**Hook**: Application author/integrator-supplied logic that is called by the OpenFeature framework at a specific stage.\n**Stage**: An explicit portion of the flag evaluation lifecycle. e.g. `before` being "before the evaluation is run.\n**Invocation**: A single call to evaluate a flag. `client.getBooleanValue(..)` is an invocation.\n**API**: The global API singleton.\n\n'), ('###', ' Hook context', '\n\nHook context exists to provide hooks with information about the invocation.\n\n'), ('######', ' Requirement 1.1', '\n\n> Hook context **MUST** provide: the flag key, evaluation context, default value and a list of  executed hooks by stage.\n\n\n'), ('#####', ' Condition 1.2', '\n\n> If the language type system differentiates between strings, numbers, booleans, and structures.\n\n'), ('######', ' Condition 1.2.1', '\n\n> Condition: You **MUST** provide `flag type`.\n\n\n'), ('#####', ' Requirement 1.2', '\n\n> Hook context **SHOULD** provide: provider, client\n\n\n'), ('#####', ' Requirement 1.3', '\n\n> flag key, flag type, default value properties **MUST** be immutable. If the language does not support immutability, the hook **MUST NOT** modify these properties.\n\n'), ('#####', ' Requirement 1.4', '\n\n> The evaluation context **MUST** be mutable only within the `before` hook.\n\n'), ('###', ' HookHints', '\n\n'), ('#####', ' Requirement 2.1', '\n\n> HookHints **MUST** be a map of objects.\n\n\n'), ('#####', ' Condition 2.2', '\n\n> The implementation language supports a mechanism for marking data as immutable.\n\n'), ('######', ' 2.2.1', '\n\n> Condition: HookHints **MUST** be immutable.\n\n\n'), ('###', ' Hook creation and parameters', '\n\n\n'), ('#####', ' Requirement 3.1', '\n\n> Hooks **MUST** specify at least one stage.\n\n'), ('#####', ' Requirement 3.2', '\n\n> The `before` stage **MUST** run before flag evaluation occurs. It accepts a `hook context` (required) and `state` (optional) as parameters and returns either a `HookContext` or nothing.\n\n```\nHookContext|void before(HookContext, HookHints)\n```\n\n'), ('#####', ' Requirement 3.3', '\n\n> The `after` stage **MUST** run after flag evaluation occurs. It accepts a `hook context` (required), `flag evaluation details` (required) and `HookHints` (optional). It has no return value.\n\n'), ('#####', ' Requirement 3.4', '\n\n> The `error` hook **MUST** run when errors are encountered in the `before` stage, the `after` stage or during flag evaluation. It accepts `hook context` (required), `exception` for what went wrong (required), and `HookHints` (optional). It has no return value.\n\n'), ('#####', ' Requirement 3.5', '\n\n> The `finally` hook **MUST** run after the `before`, `after`, and `error` stages. It accepts a `hook context` (required) and `HookHints` (optional). There is no return value.\n\n'), ('#####', ' Condition 3.6', '\n\n> `finally` is a reserved word in the language.\n\n'), ('######', ' 3.6.1', '\n\n> Condition: If `finally` is a reserved word in the language, `finallyAfter` **SHOULD** be used.\n\n'), ('###', ' Hook registration & ordering', '\n\n'), ('#####', ' Requirement 4.1', "\n\n> The API, Client and invocation **MUST** have a method for registering hooks which accepts `flag evaluation options`\n\n```js\nOpenFeature.addHooks(new Hook1());\n\n//...\n\nClient client = OpenFeature.getClient();\nclient.addHooks(new Hook2());\n`\n//...\n\nclient.getValue('my-flag', 'defaultValue', new Hook3());\n```\n\n"), ('#####', ' Requirement 4.2', '\n\n> Hooks **MUST** be evaluated in the following order:\n> - before: API, Client, Invocation\n> - after: Invocation, Client, API\n> - error (if applicable): Invocation, Client, API\n> - finally: Invocation, Client, API> If an error occurs in the `finally` hook, it **MUST NOT** trigger the `error` hook.\n\n'), ('#####', ' Requirement 4.3', '\n\n> If an error occurs in the `before` or `after` hooks, the `error` hooks **MUST** be invoked.\n\n'), ('#####', ' Requirement 4.4', '\n\n> If an error occurs during the evaluation of `before` or `after` hooks, any remaining hooks in the `before` or `after` stages **MUST NOT** be invoked.\n\n'), ('#####', ' Requirement 4.5', '\n\n> If an error is encountered in the error stage, it **MUST NOT** be returned to the user.\n\n\n'), ('###', ' [Flag evaluation options](../types.md#evaluation-options)', "\n\nUsage might looks something like:\n\n```python\nval = client.get_boolean_value('my-key', False, evaluation_options={\n    'hooks': new MyHook(),\n    'hook_hints': {'side-item': 'onion rings'}\n})\n```\n\n"), ('#####', ' Requirement 5.1', '\n\n> `Flag evalution options` **MUST** contain a list of hooks to evaluate.\n\n'), ('#####', ' Requirement 5.2', '\n\n> `Flag evaluation options` **MAY** contain `HookHints`, a map of data to be provided to hook invocations.\n\n'), ('#####', ' Requirement 5.3', '\n\n> `HookHints` **MUST** be passed to each hook through a parameter. It is merged into the object in the precedence order API -> Client -> Invocation (last wins).\n\n```python\nhook_hints = {}\nfor source in [API, Client, Invocation]:\n  for key, value in source:\n    hook-hints[key] = value\n```\n\n'), ('#####', ' Requirement 5.4', '\n\n> The hook **MUST NOT** alter the `HookHints` object.\n\n'), ('###', ' Hook evaluation', '\n\n'), ('#####', ' Requirement 6.1', '\n\n> `HookHints` **MUST** passed between each hook.\n')]
        content = '''
        # test
        content **MUST** yes
        ## foo
        more **MUST NOT** content
        # another outer headline
        '''
        parsed_content = content_finder.findall(content)
        self.assertEqual(None, parsed_content_to_heirarchy(parsed_content))

    def test_parses_content__with_title__no_keywords(self):
        # parsed_content = [('#', ' Hooks', '\n\n'), ('##', ' Overview', '\n\nHooks are a mechanism whereby application developers can add arbitrary behavior\nto flag evaluation. They operate similarly to middleware in many web frameworks.\n\n'), ('###', ' Definitions', '\n\n**Hook**: Application author/integrator-supplied logic that is called by the OpenFeature framework at a specific stage.\n**Stage**: An explicit portion of the flag evaluation lifecycle. e.g. `before` being "before the evaluation is run.\n**Invocation**: A single call to evaluate a flag. `client.getBooleanValue(..)` is an invocation.\n**API**: The global API singleton.\n\n'), ('###', ' Hook context', '\n\nHook context exists to provide hooks with information about the invocation.\n\n'), ('######', ' Requirement 1.1', '\n\n> Hook context **MUST** provide: the flag key, evaluation context, default value and a list of  executed hooks by stage.\n\n\n'), ('#####', ' Condition 1.2', '\n\n> If the language type system differentiates between strings, numbers, booleans, and structures.\n\n'), ('######', ' Condition 1.2.1', '\n\n> Condition: You **MUST** provide `flag type`.\n\n\n'), ('#####', ' Requirement 1.2', '\n\n> Hook context **SHOULD** provide: provider, client\n\n\n'), ('#####', ' Requirement 1.3', '\n\n> flag key, flag type, default value properties **MUST** be immutable. If the language does not support immutability, the hook **MUST NOT** modify these properties.\n\n'), ('#####', ' Requirement 1.4', '\n\n> The evaluation context **MUST** be mutable only within the `before` hook.\n\n'), ('###', ' HookHints', '\n\n'), ('#####', ' Requirement 2.1', '\n\n> HookHints **MUST** be a map of objects.\n\n\n'), ('#####', ' Condition 2.2', '\n\n> The implementation language supports a mechanism for marking data as immutable.\n\n'), ('######', ' 2.2.1', '\n\n> Condition: HookHints **MUST** be immutable.\n\n\n'), ('###', ' Hook creation and parameters', '\n\n\n'), ('#####', ' Requirement 3.1', '\n\n> Hooks **MUST** specify at least one stage.\n\n'), ('#####', ' Requirement 3.2', '\n\n> The `before` stage **MUST** run before flag evaluation occurs. It accepts a `hook context` (required) and `state` (optional) as parameters and returns either a `HookContext` or nothing.\n\n```\nHookContext|void before(HookContext, HookHints)\n```\n\n'), ('#####', ' Requirement 3.3', '\n\n> The `after` stage **MUST** run after flag evaluation occurs. It accepts a `hook context` (required), `flag evaluation details` (required) and `HookHints` (optional). It has no return value.\n\n'), ('#####', ' Requirement 3.4', '\n\n> The `error` hook **MUST** run when errors are encountered in the `before` stage, the `after` stage or during flag evaluation. It accepts `hook context` (required), `exception` for what went wrong (required), and `HookHints` (optional). It has no return value.\n\n'), ('#####', ' Requirement 3.5', '\n\n> The `finally` hook **MUST** run after the `before`, `after`, and `error` stages. It accepts a `hook context` (required) and `HookHints` (optional). There is no return value.\n\n'), ('#####', ' Condition 3.6', '\n\n> `finally` is a reserved word in the language.\n\n'), ('######', ' 3.6.1', '\n\n> Condition: If `finally` is a reserved word in the language, `finallyAfter` **SHOULD** be used.\n\n'), ('###', ' Hook registration & ordering', '\n\n'), ('#####', ' Requirement 4.1', "\n\n> The API, Client and invocation **MUST** have a method for registering hooks which accepts `flag evaluation options`\n\n```js\nOpenFeature.addHooks(new Hook1());\n\n//...\n\nClient client = OpenFeature.getClient();\nclient.addHooks(new Hook2());\n`\n//...\n\nclient.getValue('my-flag', 'defaultValue', new Hook3());\n```\n\n"), ('#####', ' Requirement 4.2', '\n\n> Hooks **MUST** be evaluated in the following order:\n> - before: API, Client, Invocation\n> - after: Invocation, Client, API\n> - error (if applicable): Invocation, Client, API\n> - finally: Invocation, Client, API> If an error occurs in the `finally` hook, it **MUST NOT** trigger the `error` hook.\n\n'), ('#####', ' Requirement 4.3', '\n\n> If an error occurs in the `before` or `after` hooks, the `error` hooks **MUST** be invoked.\n\n'), ('#####', ' Requirement 4.4', '\n\n> If an error occurs during the evaluation of `before` or `after` hooks, any remaining hooks in the `before` or `after` stages **MUST NOT** be invoked.\n\n'), ('#####', ' Requirement 4.5', '\n\n> If an error is encountered in the error stage, it **MUST NOT** be returned to the user.\n\n\n'), ('###', ' [Flag evaluation options](../types.md#evaluation-options)', "\n\nUsage might looks something like:\n\n```python\nval = client.get_boolean_value('my-key', False, evaluation_options={\n    'hooks': new MyHook(),\n    'hook_hints': {'side-item': 'onion rings'}\n})\n```\n\n"), ('#####', ' Requirement 5.1', '\n\n> `Flag evalution options` **MUST** contain a list of hooks to evaluate.\n\n'), ('#####', ' Requirement 5.2', '\n\n> `Flag evaluation options` **MAY** contain `HookHints`, a map of data to be provided to hook invocations.\n\n'), ('#####', ' Requirement 5.3', '\n\n> `HookHints` **MUST** be passed to each hook through a parameter. It is merged into the object in the precedence order API -> Client -> Invocation (last wins).\n\n```python\nhook_hints = {}\nfor source in [API, Client, Invocation]:\n  for key, value in source:\n    hook-hints[key] = value\n```\n\n'), ('#####', ' Requirement 5.4', '\n\n> The hook **MUST NOT** alter the `HookHints` object.\n\n'), ('###', ' Hook evaluation', '\n\n'), ('#####', ' Requirement 6.1', '\n\n> `HookHints` **MUST** passed between each hook.\n')]
        content = '''
        # requirement 1.1
        content
        ## condition 2.3
        more
        # another outer headline
        '''
        parsed_content = content_finder.findall(content)

        output = parsed_content_to_heirarchy(parsed_content)
        self.assertEqual([
            {
                'id': '1.1',
                'clean id': '1_1',
                'content': 'content',
                'RFC 2119 keyword': None,
                'children': [{
                    'id': '2.3',
                    'clean id': '2_3',
                    'content': 'more',
                    'RFC 2119 keyword': None,
                    'children': [],
                }]
            },
        ], output)

    def test_parses_content__siblings(self):
        # parsed_content = [('#', ' Hooks', '\n\n'), ('##', ' Overview', '\n\nHooks are a mechanism whereby application developers can add arbitrary behavior\nto flag evaluation. They operate similarly to middleware in many web frameworks.\n\n'), ('###', ' Definitions', '\n\n**Hook**: Application author/integrator-supplied logic that is called by the OpenFeature framework at a specific stage.\n**Stage**: An explicit portion of the flag evaluation lifecycle. e.g. `before` being "before the evaluation is run.\n**Invocation**: A single call to evaluate a flag. `client.getBooleanValue(..)` is an invocation.\n**API**: The global API singleton.\n\n'), ('###', ' Hook context', '\n\nHook context exists to provide hooks with information about the invocation.\n\n'), ('######', ' Requirement 1.1', '\n\n> Hook context **MUST** provide: the flag key, evaluation context, default value and a list of  executed hooks by stage.\n\n\n'), ('#####', ' Condition 1.2', '\n\n> If the language type system differentiates between strings, numbers, booleans, and structures.\n\n'), ('######', ' Condition 1.2.1', '\n\n> Condition: You **MUST** provide `flag type`.\n\n\n'), ('#####', ' Requirement 1.2', '\n\n> Hook context **SHOULD** provide: provider, client\n\n\n'), ('#####', ' Requirement 1.3', '\n\n> flag key, flag type, default value properties **MUST** be immutable. If the language does not support immutability, the hook **MUST NOT** modify these properties.\n\n'), ('#####', ' Requirement 1.4', '\n\n> The evaluation context **MUST** be mutable only within the `before` hook.\n\n'), ('###', ' HookHints', '\n\n'), ('#####', ' Requirement 2.1', '\n\n> HookHints **MUST** be a map of objects.\n\n\n'), ('#####', ' Condition 2.2', '\n\n> The implementation language supports a mechanism for marking data as immutable.\n\n'), ('######', ' 2.2.1', '\n\n> Condition: HookHints **MUST** be immutable.\n\n\n'), ('###', ' Hook creation and parameters', '\n\n\n'), ('#####', ' Requirement 3.1', '\n\n> Hooks **MUST** specify at least one stage.\n\n'), ('#####', ' Requirement 3.2', '\n\n> The `before` stage **MUST** run before flag evaluation occurs. It accepts a `hook context` (required) and `state` (optional) as parameters and returns either a `HookContext` or nothing.\n\n```\nHookContext|void before(HookContext, HookHints)\n```\n\n'), ('#####', ' Requirement 3.3', '\n\n> The `after` stage **MUST** run after flag evaluation occurs. It accepts a `hook context` (required), `flag evaluation details` (required) and `HookHints` (optional). It has no return value.\n\n'), ('#####', ' Requirement 3.4', '\n\n> The `error` hook **MUST** run when errors are encountered in the `before` stage, the `after` stage or during flag evaluation. It accepts `hook context` (required), `exception` for what went wrong (required), and `HookHints` (optional). It has no return value.\n\n'), ('#####', ' Requirement 3.5', '\n\n> The `finally` hook **MUST** run after the `before`, `after`, and `error` stages. It accepts a `hook context` (required) and `HookHints` (optional). There is no return value.\n\n'), ('#####', ' Condition 3.6', '\n\n> `finally` is a reserved word in the language.\n\n'), ('######', ' 3.6.1', '\n\n> Condition: If `finally` is a reserved word in the language, `finallyAfter` **SHOULD** be used.\n\n'), ('###', ' Hook registration & ordering', '\n\n'), ('#####', ' Requirement 4.1', "\n\n> The API, Client and invocation **MUST** have a method for registering hooks which accepts `flag evaluation options`\n\n```js\nOpenFeature.addHooks(new Hook1());\n\n//...\n\nClient client = OpenFeature.getClient();\nclient.addHooks(new Hook2());\n`\n//...\n\nclient.getValue('my-flag', 'defaultValue', new Hook3());\n```\n\n"), ('#####', ' Requirement 4.2', '\n\n> Hooks **MUST** be evaluated in the following order:\n> - before: API, Client, Invocation\n> - after: Invocation, Client, API\n> - error (if applicable): Invocation, Client, API\n> - finally: Invocation, Client, API> If an error occurs in the `finally` hook, it **MUST NOT** trigger the `error` hook.\n\n'), ('#####', ' Requirement 4.3', '\n\n> If an error occurs in the `before` or `after` hooks, the `error` hooks **MUST** be invoked.\n\n'), ('#####', ' Requirement 4.4', '\n\n> If an error occurs during the evaluation of `before` or `after` hooks, any remaining hooks in the `before` or `after` stages **MUST NOT** be invoked.\n\n'), ('#####', ' Requirement 4.5', '\n\n> If an error is encountered in the error stage, it **MUST NOT** be returned to the user.\n\n\n'), ('###', ' [Flag evaluation options](../types.md#evaluation-options)', "\n\nUsage might looks something like:\n\n```python\nval = client.get_boolean_value('my-key', False, evaluation_options={\n    'hooks': new MyHook(),\n    'hook_hints': {'side-item': 'onion rings'}\n})\n```\n\n"), ('#####', ' Requirement 5.1', '\n\n> `Flag evalution options` **MUST** contain a list of hooks to evaluate.\n\n'), ('#####', ' Requirement 5.2', '\n\n> `Flag evaluation options` **MAY** contain `HookHints`, a map of data to be provided to hook invocations.\n\n'), ('#####', ' Requirement 5.3', '\n\n> `HookHints` **MUST** be passed to each hook through a parameter. It is merged into the object in the precedence order API -> Client -> Invocation (last wins).\n\n```python\nhook_hints = {}\nfor source in [API, Client, Invocation]:\n  for key, value in source:\n    hook-hints[key] = value\n```\n\n'), ('#####', ' Requirement 5.4', '\n\n> The hook **MUST NOT** alter the `HookHints` object.\n\n'), ('###', ' Hook evaluation', '\n\n'), ('#####', ' Requirement 6.1', '\n\n> `HookHints` **MUST** passed between each hook.\n')]
        content = '''
        # requirement 1.1
        content
        # condition 2.3
        more
        '''
        parsed_content = content_finder.findall(content)

        output = parsed_content_to_heirarchy(parsed_content)
        self.assertEqual([
            {
                'id': '1.1',
                'clean id': '1_1',
                'content': 'content',
                'RFC 2119 keyword': None,
                'children': []
            },
            {
                'id': '2.3',
                'clean id': '2_3',
                'content': 'more',
                'RFC 2119 keyword': None,
                'children': [],
            }
        ], output)

    def test_node_gen(self):
        node = gen_node({'headline': 'requirement 4.2', 'content': "You **MUST** be joking"})
        self.assertEqual('4.2', node['id'])
        self.assertEqual('4_2', node['clean id'])
        self.assertEqual('You MUST be joking', node['content'])
        self.assertEqual('MUST', node['RFC 2119 keyword'])

    def test_node_gen_no_content(self):
        node = gen_node({'headline': 'requirement 4.2', 'content': "You gotta be joking"})
        self.assertEqual({
            'id': '4.2',
            'clean id': '4_2',
            'content': 'You gotta be joking',
            'RFC 2119 keyword': None,
            'children': [],
        }, node)