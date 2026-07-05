SHELL := /bin/bash

SIM_NAME ?= iPhone 16
DEST := platform=iOS Simulator,name=$(SIM_NAME)

.PHONY: project build test test-packages uitest lint ci

project:
	xcodegen generate

# Note: `set -o pipefail` is inline in each recipe because macOS ships
# GNU make 3.81, which ignores .SHELLFLAGS — without it, tee masks the
# real exit code and failures pass silently.
lint:
	@mkdir -p build
	set -o pipefail; swiftlint lint --strict | tee build/lint.log

test-packages:
	@mkdir -p build
	rm -rf build/package-tests.xcresult
	set -o pipefail; cd Packages/Anchor && xcodebuild test -scheme Anchor-Package \
	  -destination '$(DEST)' -enableCodeCoverage YES \
	  -resultBundlePath ../../build/package-tests.xcresult \
	  OTHER_SWIFT_FLAGS='$$(inherited) -warnings-as-errors' 2>&1 | tee ../../build/test-packages.log

build: project
	@mkdir -p build
	set -o pipefail; xcodebuild build -scheme Anchor -project Anchor.xcodeproj \
	  -destination '$(DEST)' CODE_SIGNING_ALLOWED=NO \
	  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES 2>&1 | tee build/app-build.log

uitest: project
	@mkdir -p build
	set -o pipefail; xcodebuild test -scheme Anchor -project Anchor.xcodeproj \
	  -destination '$(DEST)' CODE_SIGNING_ALLOWED=NO \
	  -only-testing:AnchorUITests 2>&1 | tee build/app-uitest.log

test: test-packages

ci: lint test-packages build uitest
