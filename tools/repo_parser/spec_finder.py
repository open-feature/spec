#!/usr/bin/python
from __future__ import annotations

import configparser
import json
import os
import re
import sys
import urllib.request
from typing import Any, TypedDict, cast


class Config(TypedDict):
    file_extension: str
    multiline_regex: str | None
    number_subregex: str | None
    text_subregex: str | None
    inline_comment_prefix: str | None


def _demarkdown(t: str) -> str:
    return t.replace('**', '').replace('`', '').replace('"', '')


def get_spec_parser(code_dir: str) -> Config:
    with open(os.path.join(code_dir, '.specrc')) as f:
        data = '\n'.join(f.readlines())

    typical = configparser.ConfigParser(comment_prefixes=())
    typical.read_string(data)
    retval = typical['spec']

    if 'inline_comment_prefix' in retval:
        # If an `inline_comment_prefix` is set, then we're using the inline
        # comment approach, which should obviate artisnal regexes.
        retval['multiline_regex'] = r'spec:(.*?):end'
        retval['number_subregex'] = r'(?P<number>[\d.]+):'
        retval['text_subregex'] = r'[\d.]+:(.*)'
    else:
        assert 'file_extension' in retval
        assert 'multiline_regex' in retval
        assert 'number_subregex' in retval
        assert 'text_subregex' in retval
    return cast(Config, retval)


def get_spec(force_refresh: bool = False, path_prefix: str = './') -> dict[str, Any]:
    spec_path = os.path.join(path_prefix, 'specification.json')
    print('Going to look in ', spec_path)
    data = ''
    if os.path.exists(spec_path) and not force_refresh:
        with open(spec_path) as f:
            data = ''.join(f.readlines())
    else:
        # TODO: Status code check
        spec_response = urllib.request.urlopen(
            'https://raw.githubusercontent.com/open-feature/spec/main/specification.json'
        )
        raw = []
        for i in spec_response.readlines():
            raw.append(i.decode('utf-8'))
        data = ''.join(raw)
        with open(spec_path, 'w') as f:
            f.write(data)
    return json.loads(data)


def specmap_from_file(actual_spec: dict[str, Any]) -> dict[str, str]:
    spec_map = {}
    for entry in actual_spec['rules']:
        number = re.search(r'[\d.]+', entry['id']).group()
        if 'requirement' in entry['machine_id']:
            spec_map[number] = _demarkdown(entry['content'])

        if len(entry['children']) > 0:
            for ch in entry['children']:
                number = re.search(r'[\d.]+', ch['id']).group()
                if 'requirement' in ch['machine_id']:
                    spec_map[number] = _demarkdown(ch['content'])
    return spec_map


def find_covered_specs(config: Config, data: str) -> dict[str, dict[str, str]]:
    repo_specs = {}
    for match in re.findall(config['multiline_regex'], data, re.MULTILINE | re.DOTALL):
        match = match.replace('\n', '').replace(config['inline_comment_prefix'], '')
        # normalize whitespace
        match = re.sub(' {2,}', ' ', match.strip())
        number = re.findall(config['number_subregex'], match)[0]

        text_with_concat_chars = re.findall(config['text_subregex'], match, re.MULTILINE | re.DOTALL)
        try:
            text = ''.join(text_with_concat_chars).strip()
            # We have to match for ") to capture text with parens inside, so we add the trailing " back in.
            text = _demarkdown(eval('"%s"' % text))
            entry = repo_specs[number] = {
                'number': number,
                'text': text,
            }
        except Exception as e:
            print(f"Skipping {match} b/c we couldn't parse it")
    return repo_specs


def gen_report(from_spec: dict[str, str], from_repo: dict[str, dict[str, str]]) -> dict[str, set[str]]:
    extra = set()
    different_text = set()
    good = set()

    missing = set(from_spec.keys())  # assume they're all missing

    for number, text in from_repo.items():
        if number in missing:
            missing.remove(number)
        if number not in from_spec:
            extra.add(number)
            continue
        if text == from_spec[number]:
            good.add(number)
        else:
            different_text.add(number)

    return {
        'extra': extra,
        'missing': missing,
        'different-text': different_text,
        'good': good,
    }


def main(
    refresh_spec: bool = False,
    diff_output: bool = False,
    limit_numbers: str | None = None,
    code_directory: str | None = None,
    json_report: bool = False,
) -> None:
    report = {
        'extra': set(),
        'missing': set(),
        'different-text': set(),
        'good': set(),
    }

    actual_spec = get_spec(refresh_spec, path_prefix=code_directory)
    config = get_spec_parser(code_directory)

    spec_map = specmap_from_file(actual_spec)

    repo_specs = {}
    missing = set(spec_map.keys())
    bad_num = 0

    for root, dirs, files in os.walk('.', topdown=False):
        for name in files:
            F = os.path.join(root, name)
            if ('.%s' % config['file_extension']) not in name:
                continue
            with open(F) as f:
                data = ''.join(f.readlines())

            repo_specs |= find_covered_specs(config, data)

    report = gen_report(from_spec=spec_map, from_repo=repo_specs)

    for number in report['different-text']:
        bad_num += 1
        print(f'{number} is bad.')
        if diff_output:
            print('Official:')
            print('\t%s' % spec_map[number])
            print('')
            print('Ours:')
            print('\t%s' % repo_specs[number])

    bad_num += len(report['extra'])
    for number in report['extra']:
        print(f"{number} is defined in our tests, but couldn't find it in the spec")

    missing = report['missing']
    bad_num += len(missing)
    if len(missing) > 0:
        print('In the spec, but not in our tests: ')
        for m in sorted(missing):
            print(f'  {m}: {spec_map[m]}')

    if json_report:
        for k in report.keys():
            report[k] = sorted(list(report[k]))
        report_txt = json.dumps(report, indent=4)
        loc = os.path.join(code_directory, '%s-report.json' % config['file_extension'])
        with open(loc, 'w') as f:
            f.write(report_txt)
    sys.exit(bad_num)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Parse the spec to make sure our tests cover it')
    parser.add_argument('--refresh-spec', action='store_true', help='Re-downloads the spec')
    parser.add_argument('--diff-output', action='store_true', help='print the text differences')
    parser.add_argument('--code-directory', action='store', required=True, help='directory to find code in')
    parser.add_argument('--json-report', action='store_true', help='Store a json report into ${extension}-report.json')
    parser.add_argument('specific_numbers', metavar='num', type=str, nargs='*', help='limit this to specific numbers')

    args = parser.parse_args()
    main(
        refresh_spec=args.refresh_spec,
        diff_output=args.diff_output,
        limit_numbers=args.specific_numbers,
        code_directory=args.code_directory,
        json_report=args.json_report,
    )
