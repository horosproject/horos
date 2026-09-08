.PHONY: Horos clean macos-27-compatibility-check

CONFIG ?= Debug
DERIVED_DATA ?= build

Horos:
	xcodebuild -project "Horos.xcodeproj" -scheme Horos -configuration "$(CONFIG)" -derivedDataPath "$(DERIVED_DATA)"

clean:
	@rm -rf ./build

macos-27-compatibility-check:
	@./test-data/macos-27-compatibility-check.sh
