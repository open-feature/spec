IS_PYTHON_INSTALLED = $(shell which python >> /dev/null 2>&1; echo $$?)
ALL_DOCS := $(shell find . -type f -name '*.md' -not -path './.github/*' -not -path './node_modules/*' | sort)

parse: clean _check_python
	@python ./tools/specification_parser/specification_parser.py

clean:
	@find ./specification -name '*.json' -delete

lint: install
	@python ./tools/specification_parser/lint_json_output.py specification/
	./node_modules/.bin/markdownlint --ignore node_modules/ --ignore tools/ **/*.md
	./node_modules/.bin/markdown-link-check -c .markdown-link-check-config.json README.md specification/**/*.md

fix: install
	prettier -w **/*.md

install:
	npm ci

_check_python:
	@if [ $(IS_PYTHON_INSTALLED) -eq 1 ]; \
		then echo "" \
		&& echo "ERROR: python must be available on PATH." \
		&& echo "" \
		&& exit 1; \
		fi;
.PHONY: markdown-toc
markdown-toc: install
	@if ! npm ls markdown-toc; then npm ci; fi
	@for f in $(ALL_DOCS); do \
		if grep -q '<!-- tocstop -->' $$f; then \
			echo markdown-toc: processing $$f; \
			npx --no -- markdown-toc --bullets="-" --no-first-h1 --no-stripHeadingTags -i $$f || exit 1; \
		else \
			echo markdown-toc: no TOC markers, skipping $$f; \
		fi; \
	done
