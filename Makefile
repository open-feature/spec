IS_PYTHON_INSTALLED = $(shell which python >> /dev/null 2>&1; echo $$?)

parse: clean _check_python
	@python ./tools/specification_parser/specification_parser.py

clean:
	@find ./specification -name '*.json' -delete

_check_python:
	@if [ $(IS_PYTHON_INSTALLED) -eq 1 ]; \
		then echo "" \
		&& echo "ERROR: python must be available on PATH." \
		&& echo "" \
		&& exit 1; \
		fi;