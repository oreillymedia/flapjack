.PHONY: test

test: test-ios test-macos test-tvos

test-ios:
	xcodebuild -project Flapjack.xcodeproj -scheme "Tests-iOS" -destination 'platform=iOS Simulator,name=iPhone X,OS=latest' test | xcpretty --color

test-macos:
	xcodebuild -project Flapjack.xcodeproj -scheme "Tests-macOS" test | xcpretty --color

test-tvos:
	xcodebuild -project Flapjack.xcodeproj -scheme "Tests-tvOS" -destination 'platform=tvOS Simulator,name=Apple TV 4K,OS=latest' test | xcpretty --color

cocoapods-deploy:
	pod trunk push Flapjack.podspec

cocoapods-preflight:
	pod lib lint
	pod spec lint Flapjack.podspec 

release:
	jazzy
	git add docs/
	git commit -m "Version $(VERSION)"
	git tag -s $(VERSION) -m "Version $(VERSION)"
