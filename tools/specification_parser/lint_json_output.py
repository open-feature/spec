from os.path import curdir, abspath, join, splitext
from os import walk
import json
import sys


def main(f):
    errors = 0
    with open(f) as jsonfile:
        spec = json.load(jsonfile)
        entries = [];
        for entry in spec['rules']:
            entries.append(entry)
            for child in entry.get('children', []):
                entries.append(child)
        try:
            for entry in entries:
                if entry.get('RFC 2119 keyword') is None and \
                   'condition' not in entry['id'].lower():
                    print(f"{j}: Rule {entry['id']} is missing a RFC 2119 keyword", file=sys.stderr)
                    errors += 1
                pass
        except Exception as k:
            print(f"Non json-spec formatted file found: {j}", file=sys.stderr)

    sys.exit(errors)

if __name__ == '__main__':
    main(sys.argv[1])
