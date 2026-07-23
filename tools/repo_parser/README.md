# Repo Parser

This will parse the contents of an OpenFeature repo and determine how they adhere to the spec. This can be gamed and
assumes everyone is participating in good faith.

We look for a `.specrc` file in the root of a repository to figure out how to find test cases that are annotated with
the spec number and the text of the spec. We can then produce a report which says "you're covered" or details about how
you're not covered. The goal of this is to use that resulting report to power a spec-compliance matrix for end users to
vet SDK quality.

## GitHub Action

The easiest way to run the compliance check is via the composite action. Add the following to your repo's workflow:

Note - using the main tag is not recommended for security, but to avoid requiring to update this documentation to the
latest pinned tag, it's shown here for example purposes. Please pin to a specific tag in production use.

```yaml
jobs:
  spec-compliance:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: open-feature/spec/tools/repo_parser@main
```

The action always fetches the latest spec, runs the compliance check, and logs a summary. The job fails if any
requirements are missing, mismatched, or reference a non-existent spec entry.

### Inputs

| Input           | Description                                                     | Default  |
|-----------------|-----------------------------------------------------------------|----------|
| `image-version` | Tag of the `ghcr.io/open-feature/spec/repo_parser` image to use | `latest` |

### Outputs

All outputs are available to subsequent steps via `if: always()`.

| Output                 | Type        | Description                                                        |
|------------------------|-------------|--------------------------------------------------------------------|
| `compliant`            | `string`    | `'true'` if fully compliant, `'false'` otherwise                   |
| `missing`              | JSON array  | Requirement IDs not covered by the repo (e.g. `["1.1.1","1.2.3"]`) |
| `extra`                | JSON array  | Test reference IDs not found in the spec                           |
| `different-text`       | JSON array  | Requirement IDs whose annotated text does not match the spec       |
| `missing-count`        | `string`    | Count of missing requirements                                      |
| `extra-count`          | `string`    | Count of extra references                                          |
| `different-text-count` | `string`    | Count of text mismatches                                           |
| `report`               | JSON object | Full report: `{ missing, extra, different-text, good }`            |

### Consuming outputs

```yaml
      - uses: open-feature/spec/tools/repo_parser@main
        id: compliance

      - if: always()
        run:
          echo "Missing requirements: ${{ steps.compliance.outputs.missing }}"
```

See [`examples/spec-compliance.yml`](examples/spec-compliance.yml) for a complete workflow.

## Docker

```
$ docker build -t specfinder .
$ docker run --mount src=/path/to/java-sdk/,target=/appdir,type=bind -it specfinder \
    --code-directory /appdir --diff-output --json-report
```

## `.specrc`

This should be at the root of the repository.

`multiline_regex` captures the text which contains the test marker. In java, for instance, it's a specially crafted
annotation. `number_subregex` and `text_subregex` which will match the substring found in the `multiline_regex` to parse
the spec number and text found. These are multi-line regexes.

Example:

```conf
[spec]
file_extension=java
multiline_regex=@Specification\((?P<innards>.*?)\)\s*$
number_subregex=number\s*=\s*['"](.*?)['"]
text_subregex=text\s*=\s*['"](.*)['"]
```

You can test the regex in python like this to validate they work:

```
$ python3
Python 3.9.6 (default, Feb  3 2024, 15:58:27)
[Clang 15.0.0 (clang-1500.3.9.4)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>> import re
>>> text = '''    @Specification(number="4.3.6", text="The after stage MUST run after flag resolution occurs. It accepts a hook context (required), flag evaluation details (required) and hook hints (optional). It has no return value.")
...     @Specification(number="4.3.7", text="The error hook MUST run when errors are encountered in the before stage, the after stage or during flag resolution. It accepts hook context (required), exception representing what went wrong (required), and hook hints (optional). It has no return value.")
... '''
>>> entries = re.findall(r'@Specification\((?P<innards>.*?)\)\s*$', text, re.MULTILINE | re.DOTALL)
>>> entries
['number="4.3.7", text="The error hook MUST run when errors are encountered in the before stage, the after stage or during flag resolution. It accepts hook context (required), exception representing what went wrong (required), and hook hints (optional). It has no return value."']
>>> re.findall(r'''number\s*=\s*['"](.*?)['"]''', entries[0], re.MULTILINE | re.DOTALL)
['4.3.7']
>>> re.findall(r'''text\s*=\s*['"](.*)['"]''', entries[0], re.MULTILINE | re.DOTALL)
['The error hook MUST run when errors are encountered in the before stage, the after stage or during flag resolution. It accepts hook context (required), exception representing what went wrong (required), and hook hints (optional). It has no return value.']
```
