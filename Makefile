.PHONY: all secrets test showCoverage analysis run ipa ios appStoreRelease android playStoreRelease icons screenshots mocks clean

CODE = $(wildcard lib/**) $(wildcard test/**)
ASSETS = $(wildcard assets/**)
SOURCES = $(CODE) $(ASSETS)

all: analysis showCoverage

secrets:
	[ -f .env ] && source .env; flutter pub run tool/generate_secrets_file.dart

test: coverage/lcov.info

coverage/lcov.info: $(SOURCES)
	flutter test --coverage

coverage/html/index.html: coverage/lcov.info
	genhtml -q coverage/lcov.info -o coverage/html

showCoverage: coverage/html/index.html
	open coverage/html/index.html

analysis: analysis.txt

analysis.txt: $(CODE) analysis_options.yaml
	flutter analyze --write analysis.txt

run: test
	flutter run --release $(if $(DEVICE),-d "$(DEVICE)")

icons:
	flutter pub run flutter_launcher_icons:main

ipa: test
	flutter build ios --release \
    && mkdir -p build/ios/iphoneos/Payload \
    && cd build/ios/iphoneos \
    && rm -rf Payload/Runner.app app.ipa \
    && mv Runner.app Payload/ \
    && zip -r app.ipa Payload

ios: test
	flutter build ios --release

appStoreRelease: test
	cd ios && fastlane release

android: test
	flutter build appbundle --release

playStoreRelease: android
	cd android && fastlane release

screenshots:
	screenshots \
	&& cd ios/fastlane/screenshots/en-US \
	&& fastlane frameit

mocks:
	flutter pub run build_runner build

clean:
	flutter clean