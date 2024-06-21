#!/usr/bin/env bats

# How to run this test:
# from the root directory, run:
# git submodule add https://github.com/bats-core/bats-core.git test/bats
# git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support
# git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert

# Then to run tests (from root directory) run:
# /test/bats/bin/bats bin/test_fix_dates.sh

# get the containing directory of this file
# use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
# as those will point to the bats executable's location or the preprocessed file respectively
DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
# make executables in src/ visible to PATH
PATH="$DIR/../src:$PATH"
FIX_DATES="$DIR/fix_dates.sh"

load '../test/test_helper/bats-support/load'
load '../test/test_helper/bats-assert/load'

setup() {
  # Create a temporary directory for testing
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
}

teardown() {
  # Clean up after tests
  rm -rf "$TEST_DIR"
}

@test "Can run fix_dates.sh" {
  run bash $FIX_DATES
  [ "$status" -eq 0 ]
}

@test "Test mode activation" {
  touch "file_2023-04-01.txt"
  run bash $FIX_DATES -t "file_2023-04-01.txt"
  assert_output --partial "Would move file_2023-04-01.txt to 20230401_file_2023-04-01.txt"
}

@test "Date reformatting: yyyyMMdd" {
  result=$(bash $FIX_DATES -c "reformat_date 20230401")
  [ "$result" = "20230401" ]
}

@test "Date reformatting: mmddyyyy" {
  result=$(bash $FIX_DATES -c "reformat_date 04-01-2023")
  [ "$result" = "20230401" ]
}

@test "Date reformatting: mmddyy" {
  result=$(bash $FIX_DATES -c "reformat_date 040123")
  [ "$result" = "20230401" ]
}

@test "Date reformatting: mm dd yy" {
  result=$(bash $FIX_DATES -c "reformat_date '04 02 24'")
  [ "$result" = "20240402" ]
}

@test "File processing" {
  touch "event_2023-04-01.txt"
  bash $FIX_DATES "event_2023-04-01.txt"
  [ -f "20230401_event_2023-04-01.txt" ]
}

@test "Directory processing" {
  mkdir "testdir"
  touch "testdir/event_2023-04-01.txt"
  bash $FIX_DATES  "testdir"
  [ -f "testdir/20230401_event_2023-04-01.txt" ]
}

@test "Error handling: Invalid date format" {
  run bash $FIX_DATES -c "reformat_date abcdefgh"
  assert_output --partial "Unrecognized date format"
}

@test "Error handling: No date in filename" {
  touch "nofiledate.txt"
  run bash $FIX_DATES "nofiledate.txt"
  assert_output --partial ""
}