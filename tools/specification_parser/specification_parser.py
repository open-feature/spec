import re
import glob
import json
from os.path import curdir, abspath, join, splitext, isfile
from os import walk

rfc_2119_keywords_regexes = [
    r"MUST",
    r"REQUIRED",
    r"SHALL",
    r"MUST NOT",
    r"SHALL NOT",
    r"SHOULD",
    r"RECOMMENDED",
    r"SHOULD NOT",
    r"NOT RECOMMENDED",
    r"MAY",
    r"OPTIONAL",
]

def get_ignored_path_globs(root):
    fileName = join(root, ".specignore")
    if not isfile(fileName):
        return []

    with open(fileName, 'r') as f:
        # trim whitespace
        globs = [line.strip() for line in f.readlines()]
        
        # remove empty lines
        globs = [g for g in globs if g]

        # remove comments
        globs = [g for g in globs if not g.startswith('#')]

        return globs

def get_ignored_paths(root):
    globs = get_ignored_path_globs(root)
    globbed_paths = set()
    ignored_files = set()

    for g in globs:
        globbed_paths.update(glob.glob(g, recursive=True))

    for p in globbed_paths:
        if isfile(p):
            ignored_files.add(join(root, p))
        else:
            ignored_files.update(glob.glob(join(root, p, "**/*.md"), recursive=True))

    return ignored_files

def find_markdown_file_paths(root):
    'Finds the .md files in the root provided.'
    markdown_file_paths = []
    ignored_paths = get_ignored_paths(root)

    for root_path, _, file_paths, in walk(root):
        for file_path in file_paths:

            absolute_file_path = join(root_path, file_path)

            if absolute_file_path in ignored_paths:
                continue

            _, file_extension = splitext(absolute_file_path)

            if file_extension == ".md":
                markdown_file_paths.append(absolute_file_path)

    return markdown_file_paths


def clean_content(content):
    'Transmutes markdown content to plain text'
    lines = content.splitlines()
    content = '\n'.join([x for x in lines if x.strip() != '' and x.strip().startswith('>')])

    for rfc_2119_keyword_regex in rfc_2119_keywords_regexes:
        content = re.sub(
            f"\\*\\*{rfc_2119_keyword_regex}\\*\\*",
            rfc_2119_keyword_regex,
            content
        )
    return re.sub(r"\n?>\s*", " ", content.strip()).strip()


def find_rfc_2119_keyword(content):
    'Returns the RFC2119 keyword, if present'
    for rfc_2119_keyword_regex in rfc_2119_keywords_regexes:

        if re.search(
            f"\\*\\*{rfc_2119_keyword_regex}\\*\\*", content
        ) is not None:
            return rfc_2119_keyword_regex

def parsed_content_to_hierarchy(parsed_content):
    'Turns a bunch of headline & content pairings into a tree of requirements'
    content_tree = []
    headline_stack = []

    node = lambda l,h,c: {'level': l, 'headline': h, 'content': c, 'children': []}

    for level, headline, content in parsed_content:
        try:
            if len(headline_stack) == 0: # top-most node
                cur = node(level, headline, content)
                content_tree.append(cur)
                headline_stack.insert(0, [level, headline, cur])
            elif len(headline_stack[0][0]) >= len(level): # Sibling or parent node
                if len(headline_stack[0][0]) > len(level): # parent, right?
                    headline_stack.pop(0)
                headline_stack.pop(0)
                if len(headline_stack) == 0:
                    parent = content_tree
                else:
                    parent = headline_stack[0][2]['children']
                cur = node(level, headline, content)
                parent.append(cur)
                headline_stack.insert(0, [level, headline, cur])
            elif len(level) > len(headline_stack[0][0]): # child node
                # TODO: emit warning if headlines are too deep
                cur = node(level, headline, content)
                parent = headline_stack[0][2]
                parent['children'].append(cur)
                headline_stack.insert(0, [level, headline, cur])
            else:
                headline_stack.pop(0)
        except Exception as k:
            print(k);

    # Specify a root so we know that everything is a node all the way down.
    root = node(0, '', '')
    root['children'] = content_tree
    return content_tree_to_spec(root)

def gen_node(ct):
    'given a content node, turn it into a requirements node'
    headline = ct['headline']
    content = ct['content']
    keyword = find_rfc_2119_keyword(content)

    req_group = re.search(r'(?P<req>(requirement|condition)[^\n]+)', headline, re.IGNORECASE)
    if req_group is None:
        return None

    _id = req_group.groups()[0]
    return {
        'id': _id,
        'machine_id': re.sub(r"[^\w]", "_", _id.lower()),
        'content': clean_content(content),
        'RFC 2119 keyword': keyword,
        'children': [],
    }

def content_tree_to_spec(ct):
    current = gen_node(ct)
    children_grouped = [content_tree_to_spec(x) for x in ct['children']]
    # Filter out potential None entries.
    children = []
    for _iter in children_grouped:
        '''
        So we might get a None (skip it), an object (add it to the list) or another list (merge it with list).
        '''
        if _iter is None:
            continue
        if type(_iter) == list:
            children.extend(_iter)
        else:
            children.append(_iter)

    if current is None:
        if len(children) > 0:
            return children
        return
    else:
        current['children'] = children
        return current


def parse(markdown_file_path):
    with open(markdown_file_path, "r") as markdown_file:
        content_finder = re.compile(r'^(?P<level>####+)(?P<headline>[^\n]+)\n+?.*?\n+?(?P<rest>>\s[^#?]*)', re.MULTILINE)
        parsed = content_finder.findall(markdown_file.read())
        return parsed_content_to_hierarchy(parsed)

def write_json_specifications(requirements):
    for md_absolute_file_path, requirement_sections in requirements.items():
        with open(
            "".join([splitext(md_absolute_file_path)[0], ".json"]), "w"
        ) as json_file:
            json_file.write(json.dumps(requirement_sections, indent=4))


if __name__ == "__main__":
    combined = {"rules": []}
    for markdown_file_path in find_markdown_file_paths(
        join(abspath(curdir))
    ):
        result = parse(markdown_file_path)
        if result:
            combined['rules'].extend(result)

    combined['rules'] = sorted(combined['rules'], key=lambda x: [int(x) for x in x['id'].split(' ')[-1].split('.')])
    with open('./specification.json', 'w') as f:
        json.dump(combined, f, indent=4)
