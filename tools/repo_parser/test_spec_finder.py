import re
from spec_finder import find_covered_specs, gen_report

def test_simple_singleline():
    text = """
    // spec:4.3.6:The after stage MUST run after flag resolution occurs. It accepts a hook context (required), flag evaluation details (required) and hook hints (optional). It has no return value.:end
    """
    cfg = {
        'multiline_regex': r'spec:(.*):end',
        'number_subregex': r'(?P<number>[\d.]+):',
        'text_subregex': r'[\d.]+:(.*)',
        'inline_comment_prefix': '//',
    }
    output = find_covered_specs(cfg, text)
    assert '4.3.6' in output
    assert output['4.3.6']['text'] == "The after stage MUST run after flag resolution occurs. It accepts a hook context (required), flag evaluation details (required) and hook hints (optional). It has no return value."


def test_multiline_comment():
    text = """
    // spec:4.3.7:The error hook MUST run when errors are encountered in the
    // before stage, the after stage or during flag resolution. It accepts hook
    // context (required), exception representing what went wrong (required), and
    // hook hints (optional). It has no return value.:end
    """
    cfg = {
        'multiline_regex': r'spec:(.*):end',
        'number_subregex': r'(?P<number>[\d.]+):',
        'text_subregex': r'[\d.]+:(.*)',
        'inline_comment_prefix': '//',
    }
    output = find_covered_specs(cfg, text)
    assert '4.3.7' in output
    assert output['4.3.7']['text'] == """The error hook MUST run when errors are encountered in the before stage, the after stage or during flag resolution. It accepts hook context (required), exception representing what went wrong (required), and hook hints (optional). It has no return value."""


def test_report():
    spec = {
        '1.2.3': "good text",
        '2.3.4': 'different text',
        '3.4.5': 'missing'
    }

    repo = {
        '1.2.3': 'good text',
        '2.3.4': 'it is different',
        '4.5.6': 'extra'
    }

    report = gen_report(spec, repo)
    assert len(report['good']) == 1
    assert len(report['different-text']) == 1
    assert len(report['missing']) == 1
    assert len(report['extra']) == 1

    assert report['good'] == set(['1.2.3'])
    assert report['different-text'] == set(['2.3.4'])
    assert report['missing'] == set(['3.4.5'])
    assert report['extra'] == set(['4.5.6'])
