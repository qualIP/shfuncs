help:

.PHONY: help check test

help:
	@echo "Please provide a target: check test" >&2
	@exit 1

check:
	shellcheck --norc --shell=bash --format=gcc func-*.sh tests/test-*

test:
	./tests/test-all
