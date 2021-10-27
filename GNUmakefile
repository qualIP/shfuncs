help:

.PHONY: help check test

help:
	@echo "Please provide a target: check test" >&2
	@exit 1

check:
	shellcheck --norc --shell=bash --format=gcc func-*.sh tests/test-* \
		| grep -v '^func-assert.sh:.*SC2034' \
		| grep -v '^func-git.sh:.*warning: EGIT_BISECT_CANT_TEST appears unused.*SC2034' \

test:
	./tests/test-all
