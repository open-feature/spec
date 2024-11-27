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
    multiline_regex: str
    number_subregex: str
    text_subregex: str
    inline_comment_prefix: str | None


Report = TypedDict(
    'Report',
    {
        'extra': list[str],
        'missing': list[str],
        'different-text': list[str],
        'good': list[str],
    },
)


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
    return cast('dict[str, Any]', json.loads(data))


def specmap_from_file(actual_spec: dict[str, Any]) -> dict[str, str]:
    spec_map = {}
    for entry in actual_spec['rules']:
        if 'requirement' in entry['machine_id']:
            if number := re.search(r'[\d.]+', entry['id']):
                spec_map[number.group()] = _demarkdown(entry['content'])
            else:
                print(f'Skipping invalid ID {entry["id"]}')

        if entry['children']:
            for ch in entry['children']:
                if 'requirement' in ch['machine_id']:
                    if number := re.search(r'[\d.]+', ch['id']):
                        spec_map[number.group()] = _demarkdown(ch['content'])
                    else:
                        print(f'Skipping invalid child ID {ch["id"]}')
    return spec_map


def find_covered_specs(config: Config, data: str) -> dict[str, str]:
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
            repo_specs[number] = text
        except Exception as e:
            print(f"Skipping {match} b/c we couldn't parse it")
    return repo_specs


def gen_report(from_spec: dict[str, str], from_repo: dict[str, str]) -> Report:
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
        'extra': sorted(extra),
        'missing': sorted(missing),
        'different-text': sorted(different_text),
        'good': sorted(good),
    }


def main(
    code_directory: str,
    refresh_spec: bool = False,
    diff_output: bool = False,
    limit_numbers: str | None = None,
    json_report: bool = False,
) -> None:
    actual_spec = get_spec(refresh_spec, path_prefix=code_directory)
    config = get_spec_parser(code_directory)

    spec_map = specmap_from_file(actual_spec)

    repo_specs: dict[str, str] = {}
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
    if missing:
        print('In the spec, but not in our tests: ')
        for m in sorted(missing):
            print(f'  {m}: {spec_map[m]}')

    if json_report:
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
        code_directory=args.code_directory,
        refresh_spec=args.refresh_spec,
        diff_output=args.diff_output,
        limit_numbers=args.specific_numbers,
        json_report=args.json_report,
    )
