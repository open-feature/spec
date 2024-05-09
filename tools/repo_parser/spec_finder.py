#!/usr/bin/python
import urllib.request
import json
import re
import difflib
import os
import sys
import configparser

def _demarkdown(t):
    return t.replace('**', '').replace('`', '').replace('"', '')

def get_spec_parser(code_dir):
    with open(os.path.join(code_dir, '.specrc')) as f:
        data = '\n'.join(f.readlines())

    typical = configparser.ConfigParser()
    typical.read_string(data)
    retval = typical['spec']
    assert 'file_extension' in retval
    assert 'multiline_regex' in retval
    assert 'number_subregex' in retval
    assert 'text_subregex' in retval
    return retval



def get_spec(force_refresh=False, path_prefix="./"):
    spec_path = os.path.join(path_prefix, 'specification.json')
    print("Going to look in ", spec_path)
    data = ""
    if os.path.exists(spec_path) and not force_refresh:
        with open(spec_path) as f:
            data = ''.join(f.readlines())
    else:
        # TODO: Status code check
        spec_response = urllib.request.urlopen('https://raw.githubusercontent.com/open-feature/spec/main/specification.json')
        raw = []
        for i in spec_response.readlines():
            raw.append(i.decode('utf-8'))
        data = ''.join(raw)
        with open(spec_path, 'w') as f:
            f.write(data)
    return json.loads(data)


def main(refresh_spec=False, diff_output=False, limit_numbers=None, code_directory=None, json_report=False):
    report = {
        'extra': set(),
        'missing': set(),
        'different-text': set(),
        'good': set(),
    }

    actual_spec = get_spec(refresh_spec, path_prefix=code_directory)
    config = get_spec_parser(code_directory)

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

    repo_specs = {}
    missing = set(spec_map.keys())

    for root, dirs, files in os.walk(".", topdown=False):
        for name in files:
            F = os.path.join(root, name)
            if ('.%s' % config['file_extension']) not in name:
                continue
            with open(F) as f:
                data = ''.join(f.readlines())

            for match in re.findall(config['multiline_regex'], data, re.MULTILINE | re.DOTALL):
                match = match.replace('\n', '')
                number = re.findall(config['number_subregex'], match)[0]

                if number in missing:
                    missing.remove(number)
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

    bad_num = len(missing)
    for number, entry in sorted(repo_specs.items(), key=lambda x: x[0]):
        if limit_numbers is not None and len(limit_numbers) > 0 and number not in limit_numbers:
            continue
        if number in spec_map:
            txt = entry['text']
            if txt == spec_map[number]:
                report['good'].add(number)
                continue
            else:
                print(f"{number} is bad.")
                report['different-text'].add(number)
                bad_num += 1
                if diff_output:
                    print("Official:")
                    print("\t%s" % spec_map[number])
                    print("")
                    print("Ours:")
                    print("\t%s" % txt)
                continue

        report['extra'].add(number)
        print(f"{number} is defined in our tests, but couldn't find it in the spec")
    print("")

    if len(missing) > 0:
        report['missing'] = missing
        print('In the spec, but not in our tests: ')
        for m in sorted(missing):
            print(f"  {m}: {spec_map[m]}")

    if json_report:
        for k in report.keys():
            report[k] = sorted(list(report[k]))
        report_txt = json.dumps(report, indent=4)
        loc = '/appdir/%s-report.json' % config['file_extension']
        with open(loc, 'w') as f:
            f.write(report_txt)
    sys.exit(bad_num)


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Parse the spec to make sure our tests cover it')
    parser.add_argument('--refresh-spec', action='store_true', help='Re-downloads the spec')
    parser.add_argument('--diff-output', action='store_true', help='print the text differences')
    parser.add_argument('--code-directory', action='store', required=True, help='directory to find code in')
    parser.add_argument('--json-report', action='store_true', help="Store a json report into ${extension}-report.json")
    parser.add_argument('specific_numbers', metavar='num', type=str, nargs='*',
                        help='limit this to specific numbers')

    args = parser.parse_args()
    main(
        refresh_spec=args.refresh_spec,
        diff_output=args.diff_output,
        limit_numbers=args.specific_numbers,
        code_directory=args.code_directory,
        json_report=args.json_report,
    )
