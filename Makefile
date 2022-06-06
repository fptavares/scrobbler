.PHONY: all secrets test showCoverage analysis run ipa ios appStoreRelease android playStoreRelease testFlight icons macos screenshots mocks installOnMacos container firebaseOptions dependencies clean

CODE = $(wildcard app/lib/**) $(wildcard app/test/**) $(wildcard pkgs/*/lib/**) $(wildcard pkgs/*/test/**)
ASSETS = $(wildcard assets/**)
SOURCES = $(CODE) $(ASSETS)

all: analysis showCoverage

secrets:
	[ -f .env ] && source .env; cd app && flutter pub run tool/generate_secrets_file.dart

test: 
	./tool/run_tests.sh

report:
	./tool/run_tests.sh --report

run:
	cd app && flutter run --release $(if $(DEVICE),-d "$(DEVICE)")

icons:
	cd app && flutter pub run flutter_launcher_icons:main

ipa:
	cd app && flutter build ipa --release

ios:
	cd app && flutter build ios --release

appStoreRelease:
	cd app/ios && fastlane release

testflight: ipa
	cd app/ios && fastlane beta

android:
	cd app && flutter build appbundle --release

playStoreRelease: android
	cd app/android && fastlane release

macos:
	cd app && flutter build macos --release

installOnMacos: macos
	rm -rf /Applications/Scrobbler.app \
	&& cp -r app/build/macos/Build/Products/Release/scrobbler.app /Applications/Scrobbler.app

container:
	docker build -t scrobbler-bluos-monitor -f pkgs/bluos_monitor_server/Dockerfile .

screenshots:
	cd app && screenshots \
	&& cd ios/fastlane/screenshots/en-US \
	&& fastlane frameit

mocks:
	cd app && flutter pub run build_runner build --delete-conflicting-outputs

firebaseOptions:
	cd app && flutter pub run tool/generate_firebase_options_file.dart

dependencies:
	( cd app && flutter pub get ) \
	&& ( cd pkgs/bluos_monitor && dart pub get ) \
	&& ( cd pkgs/bluos_monitor_server && dart pub get )

clean:
	cd app && flutter clean