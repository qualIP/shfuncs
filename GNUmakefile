help:

.PHONY: help check test

help:
	@echo "Please provide a target: check test" >&2
	@exit 1

check:
	shellcheck --norc --shell=bash --format=gcc func-*.sh tests/test-*

.PHONY: test-bash test-zsh
test: test-bash test-zsh

test-bash:
	./tests/test-all

test-zsh:
	zsh ./tests/test-all
