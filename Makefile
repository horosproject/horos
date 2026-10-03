.PHONY: Horos clean

CONFIG ?= Debug
DERIVED_DATA ?= build

# CMake 4 removed compatibility with cmake_minimum_required() < 3.5, still used by some submodules (CharLS, Grok)
export CMAKE_POLICY_VERSION_MINIMUM ?= 3.5

# `make ADHOC=1` signs ad-hoc (local use), for when you're not a member of the project's development team
ifdef ADHOC
SIGNING = CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual PROVISIONING_PROFILE_SPECIFIER=
endif

Horos:
	xcodebuild -project "Horos.xcodeproj" -scheme Horos -configuration "$(CONFIG)" -derivedDataPath "$(DERIVED_DATA)" $(SIGNING)

clean:
	@rm -rf ./build
