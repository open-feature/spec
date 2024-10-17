from spec_finder import Config, find_covered_specs, gen_report, specmap_from_file


def test_simple_singleline():
    text = """
    // spec:4.3.6:The after stage MUST run after flag resolution occurs. It accepts a hook context (required), flag evaluation details (required) and hook hints (optional). It has no return value.:end
    """
    cfg: Config = {
        'file_extension': 'rust',
        'multiline_regex': r'spec:(.*):end',
        'number_subregex': r'(?P<number>[\d.]+):',
        'text_subregex': r'[\d.]+:(.*)',
        'inline_comment_prefix': '//',
    }
    output = find_covered_specs(cfg, text)
    assert '4.3.6' in output
    assert (
        output['4.3.6']
        == 'The after stage MUST run after flag resolution occurs. It accepts a hook context (required), flag evaluation details (required) and hook hints (optional). It has no return value.'
    )


def test_multiline_comment():
    text = """
    // spec:4.3.7:The error hook MUST run when errors are encountered in the
    // before stage, the after stage or during flag resolution. It accepts hook
    // context (required), exception representing what went wrong (required), and
    // hook hints (optional). It has no return value.:end
    """
    cfg: Config = {
        'file_extension': 'rust',
        'multiline_regex': r'spec:(.*):end',
        'number_subregex': r'(?P<number>[\d.]+):',
        'text_subregex': r'[\d.]+:(.*)',
        'inline_comment_prefix': '//',
    }
    output = find_covered_specs(cfg, text)
    assert '4.3.7' in output
    assert (
        output['4.3.7']
        == """The error hook MUST run when errors are encountered in the before stage, the after stage or during flag resolution. It accepts hook context (required), exception representing what went wrong (required), and hook hints (optional). It has no return value."""
    )


def test_report():
    spec = {
        '1.2.3': 'good text',
        '2.3.4': 'different text',
        '3.4.5': 'missing',
    }

    repo = {
        '1.2.3': 'good text',
        '2.3.4': 'it is different',
        '4.5.6': 'extra',
    }

    report = gen_report(spec, repo)
    assert len(report['good']) == 1
    assert len(report['different-text']) == 1
    assert len(report['missing']) == 1
    assert len(report['extra']) == 1

    assert report['good'] == ['1.2.3']
    assert report['different-text'] == ['2.3.4']
    assert report['missing'] == ['3.4.5']
    assert report['extra'] == ['4.5.6']


def test_report_with_found_spec():
    spec = {
        '4.3.6': 'good text',
    }
    text = """
        // spec:4.3.6:good text:end
        """
    cfg: Config = {
        'file_extension': 'rust',
        'multiline_regex': r'spec:(.*):end',
        'number_subregex': r'(?P<number>[\d.]+):',
        'text_subregex': r'[\d.]+:(.*)',
        'inline_comment_prefix': '//',
    }
    output = find_covered_specs(cfg, text)
    report = gen_report(spec, output)

    assert report['good'] == ['4.3.6']


def test_specmap_from_file():
    actual_spec = {
        'rules': [
            {
                'id': 'Requirement 1.1.1',
                'machine_id': 'requirement_1_1_1',
                'content': 'The `API`, and any state it maintains SHOULD exist as a global singleton, even in cases wherein multiple versions of the `API` are present at runtime.',
                'RFC 2119 keyword': 'SHOULD',
                'children': [],
            },
            {
                'id': 'Condition 2.2.2',
                'machine_id': 'condition_2_2_2',
                'content': 'The implementing language type system differentiates between strings, numbers, booleans and structures.',
                'RFC 2119 keyword': None,
                'children': [
                    {
                        'id': 'Conditional Requirement 2.2.2.1',
                        'machine_id': 'conditional_requirement_2_2_2_1',
                        'content': 'The `feature provider` interface MUST define methods for typed flag resolution, including boolean, numeric, string, and structure.',
                        'RFC 2119 keyword': 'MUST',
                        'children': [],
                    }
                ],
            },
        ]
    }

    spec_map = specmap_from_file(actual_spec)

    assert len(spec_map) == 2
    assert (
        spec_map['1.1.1']
        == 'The API, and any state it maintains SHOULD exist as a global singleton, even in cases wherein multiple versions of the API are present at runtime.'
    )
    assert (
        spec_map['2.2.2.1']
        == 'The feature provider interface MUST define methods for typed flag resolution, including boolean, numeric, string, and structure.'
    )
