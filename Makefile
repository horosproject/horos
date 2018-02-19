.PHONY: Horos clean

Horos:
	xcodebuild -project "Horos.xcodeproj" -target Horos

clean:
	@rm -rf ./build
