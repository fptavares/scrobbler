.PHONY: all secrets test analysis showCoverage analysis run icons clean

CODE = $(wildcard lib/**) $(wildcard test/**)
ASSETS = $(wildcard assets/**) $(wildcard fonts/**)
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

clean:
	flutter clean