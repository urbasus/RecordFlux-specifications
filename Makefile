VERBOSE ?= @

python-packages := tests tools

# Validation test configuration
#
# VALIDATION_TESTS:		  List of validation test cases to run
# MESSAGE_<testcasename>: Set message to test in <testcasename>
# SPEC_<testcasename>:	  Set specification file to use (may be empty,
#								  defaults to <testcasename>.rflx)

VALIDATION_TESTS = arp ethernet

MESSAGE_ethernet = Ethernet::Frame
MESSAGE_arp = ARP::IPv4

.PHONY: all check check_black check_isort check_flake8 check_pylint check_mypy format test test_python

all: check test

check: check_black check_isort check_flake8 check_pylint check_mypy

check_black:
	black --check --diff --line-length 100 $(python-packages)

check_isort:
	isort --check --diff $(python-packages)

check_flake8:
	flake8 $(python-packages)

check_pylint:
	pylint $(python-packages)

check_mypy:
	mypy --pretty $(python-packages)

format:
	black -l 100 $(python-packages)
	isort $(python-packages)

test: test_python test_validation

test_python:
	python3 -m pytest -n$(shell nproc) -vv

test_validation: $(addprefix test_validation_,$(VALIDATION_TESTS))

spec = $(if $(SPEC_$1),$(SPEC_$1).rflx,$1.rflx)

test_validation_%:
	@echo "=== Validation test: $* ==="
	@if [ ! -f "$(call spec,$*)" ]; then echo "Specification \"$(call spec,$*)\" does not exist"; false; fi
	@if [ -z "$(MESSAGE_$*)" ]; then echo "Message for \"$*\" not set (MESSAGE_$* = ...)"; false; fi
	@if [ ! -d "tests/data/$*" ]; then echo "Test directory for \"$*\" does not exist (tests/data/$*/)"; false; fi
	@tools/validate_spec.py -s $(call spec,$*) -m $(MESSAGE_$*) -v tests/data/$*/valid/ -i tests/data/$*/invalid/
