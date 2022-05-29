#!/usr/bin/env bash

# remember some failed commands and report on exit
error=false

show_help() {
    printf "usage: $0 [--help] [--report] [<path to package>]

Tool for running all unit and widget tests with code coverage.
(run from root of repo)

where:
    <path to package>
        run tests for package at path only
        (otherwise runs all tests)
    --report
        run a coverage report
        (requires lcov installed)
    --help
        print this message

requires code coverage package
(install with 'pub global activate coverage')
"
    exit 1
}

# run unit and widget tests
runTests () {
  cd $1;
  if [ $? -eq 0 ] && [ -f "pubspec.yaml" ] && [ -d "test" ]; then
    escapedPath="$(echo $1 | sed 's/\//\\\//g')"

    # run tests with coverage
    if grep flutter pubspec.yaml > /dev/null; then
      flutter pub get || error=true
      flutter analyze || error=true
      echo "Running flutter tests in $1"
      flutter test --coverage || error=true
    else
      # pure dart
      dart pub get || error=true
      dart analyze || error=true
      echo "Running dart tests in $1"
      dart pub global run coverage:test_with_coverage || error=true
    fi
    if [ -d "coverage" ]; then
      # combine line coverage info from package tests to a common file
      sed "s/^SF:lib/SF:$escapedPath\/lib/g" coverage/lcov.info >> $2/coverage/lcov-combined.info
    fi
  fi
  cd $2 > /dev/null
}

runReport() {
    if [ -f "coverage/lcov-combined.info" ] && ! [ "$TRAVIS" ]; then
        genhtml -q coverage/lcov-combined.info -o coverage/html-combined --no-function-coverage -s -p `pwd`
        open coverage/html-combined/index.html
    fi
}

if ! [ -d .git ]; then printf "\nError: not in root of repo"; show_help; fi

case $1 in
    --help)
        show_help
        ;;
    --report)
        if ! [ -z ${2+x} ]; then
            printf "\nError: no extra parameters required: $2"
            show_help
        fi
        runReport
        ;;
    *)
        start_time="$(date -u +%s)"
        currentDir=`pwd`
        # if no parameter passed
        if [ -z $1 ]; then
            rm -f coverage/lcov-combined.info
            runTests $currentDir $currentDir
            dirs=(`find pkgs -mindepth 1 -maxdepth 1 -type d`)
            for dir in "${dirs[@]}"; do
                runTests $dir $currentDir
            done
        else
            if [[ -d "$1" ]]; then
                runTests $1 $currentDir
            else
                printf "\nError: not a directory: $1"
                show_help
            fi
        fi
        end_time="$(date -u +%s)"
        elapsed="$(($end_time-$start_time))"
        printf "\nIt took $(date -u -r $elapsed +%T) to execute all tests\n"
        ;;
esac

# Fail the build if there was an error
if [ "$error" = true ] ;
then
    exit -1
fi
