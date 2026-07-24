from os.path import curdir, abspath, realpath, join, splitext, commonpath
from os import walk
import json
import sys


def _safe_path(f):
    # resolve symlinks and reject paths that escape the current working directory
    base = realpath(curdir)
    target = realpath(f)
    if commonpath([base, target]) != base:
        print(f"Refusing to read path outside {base}: {f}", file=sys.stderr)
        sys.exit(1)
    return target


def main(f):
    f = _safe_path(f)
    errors = 0
    with open(f) as jsonfile:
        spec = json.load(jsonfile)
        entries = [];
        machineid_seen = []
        for entry in spec['rules']:
            machineid_seen += [entry['machine_id']]
            entries.append(entry)
            for child in entry.get('children', []):
                entries.append(child)

        if len(machineid_seen) != len(set(machineid_seen)):
            duped = set([x for x in machineid_seen if machineid_seen.count(x) > 1])
            print(f"There were duplicated machine ids in the list. This means two things claim to be the same rule number. Duplicated thing: {duped}", file=sys.stderr)

        try:
            for entry in entries:
                if entry.get('RFC 2119 keyword') is None and \
                   'requirement' in entry['id'].lower():
                    print(f"{jsonfile.name}: Rule {entry['id']} is missing a RFC 2119 keyword", file=sys.stderr)
                    errors += 1
                pass
        except Exception as k:
            print(f"Non json-spec formatted file found: {jsonfile.name}", file=sys.stderr)

    sys.exit(errors)

if __name__ == '__main__':
    main(sys.argv[1])
