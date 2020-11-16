# Copyright 2020 SkyWater PDK Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

include scripts/make/git.mk
include scripts/make/conda.mk

.DEFAULT_GOAL := all

README.rst: README.src.rst docs/status.rst Makefile | $(CONDA_ENV_PYTHON)
	@rm -f README.rst
	$(IN_CONDA_ENV) rst_include include README.src.rst - \
		| sed \
			-e's@|TAG_VERSION|@$(TAG_VERSION)@g' \
			-e's@:ref:`Versioning Information`@`Versioning Information <docs/versioning.rst>`_@g' \
			-e's@:ref:`Known Issues`@`Known Issues <docs/known_issues.rst>`_@g' \
			-e's@.. warning::@*Warning*@g' \
		> README.rst


COPYRIGHT_HOLDER := SkyWater PDK Authors
FIND := find . -path ./env -prune -o -path ./.git -prune -o
ADDLICENSE := addlicense -f ./docs/license_header.txt
fix-licenses:
	@# Makefiles
	@$(FIND) -type f -name Makefile -exec $(ADDLICENSE) $(ADDLICENSE_EXTRA) -v \{\} \+
	@$(FIND) -type f -name \*.mk -exec $(ADDLICENSE) $(ADDLICENSE_EXTRA) -v \{\} \+
	@# Scripting files
	@$(FIND) -type f -name \*.sh -exec $(ADDLICENSE) $(ADDLICENSE_EXTRA) -v \{\} \+
	@$(FIND) -type f -name \*.py -exec $(ADDLICENSE) $(ADDLICENSE_EXTRA) -v \{\} \+
	@# Configuration files
	@$(FIND) -type f -name \*.yml  -exec $(ADDLICENSE) $(ADDLICENSE_EXTRA) -v \{\} \+
	@# Actual PDK files
	@$(FIND) -type f -name \*.v  -exec $(ADDLICENSE) $(ADDLICENSE_EXTRA) -v \{\} \+

.PHONY: fix-licenses

check-licenses:
	@make --no-print-directory ADDLICENSE_EXTRA=--check fix-licenses

.PHONY: check-licenses

lint-python:
	$(IN_CONDA_ENV) flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics

.PHONY: lint-python


check: check-licenses lint-python
	@true

all: README.rst
	@true

.PHONY: all


LIBRARIES = $(foreach lib, $(dir $(wildcard libraries/*/*/timing)), $(shell $(IN_CONDA_ENV) python -m skywater_pdk.liberty --list-targets $(lib)))

timing: $(LIBRARIES) | $(CONDA_ENV_PYTHON)
	@true

.PHONY: timing

libraries/%.lib:
	@$(IN_CONDA_ENV) python -m skywater_pdk.liberty $@

libraries/%.d:
	@$(IN_CONDA_ENV) python -m skywater_pdk.liberty --gen-deps $(@:.d=.lib) > $@

include $(LIBRARIES:.lib=.d)

clean::
	@rm -f $(LIBRARIES) $(LIBRARIES:.lib=.d)

.PHONY: clean

dist-clean::
	@rm -f $(LIBRARIES) $(LIBRARIES:.lib=.d)

.PHONY: dist-clean
