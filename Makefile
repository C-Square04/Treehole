# Treehole — fast test commands
#
# Usage:
#   make test         # Unit tests only (~15s) — default for everyday work
#   make test-fast    # Unit tests, no rebuild (~5s) — after a fresh `make test` or build
#   make test-full    # Everything: unit + UI tests (~3min)
#   make test-ui      # UI tests only (~2.5min)
#   make build        # Just compile, no tests (~30s)
#   make archive      # Release archive (for TestFlight)
#   make clean        # Wipe DerivedData
#
# Run a single test class:
#   make test ONLY=AnalyticsServiceTests
# Run a single test method:
#   make test ONLY=AnalyticsServiceTests/testTrackDoesNotCrash

DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
PROJECT       := Treehole/Treehole.xcodeproj
SCHEME        := Treehole
DESTINATION   := platform=iOS Simulator,name=iPhone 17 Pro
ARCHIVE_PATH  := /tmp/Treehole.xcarchive

XCB := DEVELOPER_DIR=$(DEVELOPER_DIR) /usr/bin/xcodebuild

# Build a single -only-testing flag if ONLY=... was supplied
ifdef ONLY
ONLY_FLAG := -only-testing:TreeholeTests/$(ONLY)
else
ONLY_FLAG :=
endif

.PHONY: test test-fast test-full test-ui build archive clean

test:
	@$(XCB) test \
	  -project $(PROJECT) -scheme $(SCHEME) \
	  -destination '$(DESTINATION)' \
	  -only-testing:TreeholeTests $(ONLY_FLAG) \
	  -quiet 2>&1 \
	  | grep -E '(Test Case.*(passed|failed)|error:|TEST|BUILD)' \
	  | tail -50

test-fast:
	@$(XCB) test-without-building \
	  -project $(PROJECT) -scheme $(SCHEME) \
	  -destination '$(DESTINATION)' \
	  -only-testing:TreeholeTests $(ONLY_FLAG) \
	  -quiet 2>&1 \
	  | grep -E '(Test Case.*(passed|failed)|error:|TEST)' \
	  | tail -50

test-full:
	@$(XCB) test \
	  -project $(PROJECT) -scheme $(SCHEME) \
	  -destination '$(DESTINATION)' \
	  -quiet 2>&1 \
	  | grep -E '(Test Case.*(passed|failed)|error:|TEST|BUILD)' \
	  | tail -80

test-ui:
	@$(XCB) test \
	  -project $(PROJECT) -scheme $(SCHEME) \
	  -destination '$(DESTINATION)' \
	  -only-testing:TreeholeUITests \
	  -quiet 2>&1 \
	  | grep -E '(Test Case.*(passed|failed)|error:|TEST)' \
	  | tail -50

build:
	@$(XCB) build \
	  -project $(PROJECT) -scheme $(SCHEME) \
	  -destination '$(DESTINATION)' 2>&1 \
	  | grep -E '(error:|warning:|BUILD)' | tail -10

archive:
	@rm -rf $(ARCHIVE_PATH)
	@$(XCB) archive \
	  -project $(PROJECT) -scheme $(SCHEME) \
	  -configuration Release \
	  -destination 'generic/platform=iOS' \
	  -archivePath $(ARCHIVE_PATH) 2>&1 \
	  | grep -E '(error:|ARCHIVE)' | tail -5
	@DEFAULT_DIR="$$HOME/Library/Developer/Xcode/Archives/$$(date +%Y-%m-%d)"; \
	  mkdir -p "$$DEFAULT_DIR"; \
	  cp -R $(ARCHIVE_PATH) "$$DEFAULT_DIR/Treehole $$(date +%H-%M-%S).xcarchive"; \
	  echo "Archive copied to $$DEFAULT_DIR — open Xcode → Organizer to upload"

clean:
	@rm -rf ~/Library/Developer/Xcode/DerivedData/Treehole-*
	@echo "DerivedData cleaned"
