# Repo Parser

This will parse the contents of an OpenFeature repo and determine how they adhere to the spec. This can be gamed and assumes everyone is participating in good faith.

We look for a `.specrc` file in the root of a repository to figure out how to find test cases that are annotated with the spec number and the text of the spec. We can then produce a report which says "you're covered" or details about how you're not covered. The goal of this is to use that resulting report to power a spec-compliance matrix for end users to vet SDK quality.

## Usage

```
$ docker build -t specfinder .
$ docker run --mount src=/path/tojava-sdk/,target=/appdir,type=bind -it specfinder \
    spec_finder.py --code-directory /appdir --diff --json-report
```

### `.specrc`

This should be at the root of the repository.

`multiline_regex` captures the text which contains the test marker. In java, for instance, it's a specially crafted annotation. `number_subregex` and `text_subregex` which will match the substring found in the `multiline_regex` to parse the spec number and text found. These are multi-line regexes.

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
