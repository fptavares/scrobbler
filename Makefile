.PHONY: all secrets test showCoverage analysis run ipa ios appStoreRelease android playStoreRelease testFlight icons macos screenshots mocks firebaseOptions dependencies clean

CODE = $(wildcard lib/**) $(wildcard test/**) $(wildcard pkgs/*/lib/**) $(wildcard pkgs/*/test/**)
ASSETS = $(wildcard assets/**)
SOURCES = $(CODE) $(ASSETS)

all: analysis showCoverage

secrets:
	[ -f .env ] && source .env; flutter pub run tool/generate_secrets_file.dart

test: coverage/lcov-combined.info

coverage/lcov-combined.info: $(SOURCES)
	./tool/run_tests.sh

coverage/html-combined/index.html: coverage/lcov-combined.info
	./tool/run_tests.sh --report

report: coverage/html-combined/index.html

analysis: analysis.txt

analysis.txt: $(CODE) analysis_options.yaml
	flutter analyze --write analysis.txt

run:
	flutter run --release $(if $(DEVICE),-d "$(DEVICE)")

icons:
	flutter pub run flutter_launcher_icons:main

ipa:
	flutter build ipa --release

ios:
	flutter build ios --release

appStoreRelease:
	cd ios && fastlane release

testflight:
	cd ios && fastlane beta

android:
	flutter build appbundle --release

playStoreRelease: android
	cd android && fastlane release

macos:
	flutter build macos --release

screenshots:
	screenshots \
	&& cd ios/fastlane/screenshots/en-US \
	&& fastlane frameit

mocks:
	flutter pub run build_runner build

firebaseOptions:
	flutter pub run tool/generate_firebase_options_file.dart

dependencies:
	flutter pub get \
	&& ( cd pkgs/bluos_monitor && dart pub get ) \
	&& ( cd pkgs/bluos_monitor_server && dart pub get )

clean:
	flutter clean