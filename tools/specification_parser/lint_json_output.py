from os.path import curdir, abspath, join, splitext
from os import walk
import json
import sys


def main(dir):
    jsons = []
    for root_path, _, file_paths, in walk(dir):
        for file_path in file_paths:
            absolute_file_path = join(root_path, file_path)

            _, file_extension = splitext(absolute_file_path)

            if file_extension == ".json":
                jsons.append(absolute_file_path)

    errors = 0
    for j in jsons:
        with open(j) as jfile:
            spec = json.load(jfile)
            entries = spec;
            for entry in spec:
                for child in entry.get('children', []):
                    entries.append(child)
            try:
                for entry in entries:
                    if entry['RFC 2119 keyword'] is None:
                        print(f"{j}: Rule {entry['id']} is missing a RFC 2119 keyword", file=sys.stderr)
                        errors += 1
                    pass
            except:
                print(f"Non json-spec formatted file found: {j}", file=sys.stderr)
    sys.exit(errors)

def has_errors(entry):
    pass

if __name__ == '__main__':
    main(sys.argv[1])
