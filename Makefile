SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -ec

SIM_NAME ?= iPhone 16
DEST := platform=iOS Simulator,name=$(SIM_NAME)

.PHONY: project build test test-packages lint ci

project:
	xcodegen generate

lint:
	@mkdir -p build
	swiftlint lint --strict | tee build/lint.log

test-packages:
	@mkdir -p build
	cd Packages/Anchor && xcodebuild test -scheme Anchor-Package \
	  -destination '$(DEST)' -enableCodeCoverage YES \
	  -resultBundlePath ../../build/package-tests.xcresult \
	  OTHER_SWIFT_FLAGS='$$(inherited) -warnings-as-errors' 2>&1 | tee ../../build/test-packages.log

build: project
	@mkdir -p build
	xcodebuild build -scheme Anchor -project Anchor.xcodeproj \
	  -destination '$(DEST)' CODE_SIGNING_ALLOWED=NO \
	  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES 2>&1 | tee build/app-build.log

test: test-packages

ci: lint test-packages build
