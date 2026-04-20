APP_NAME    = TaxiGo
SCHEME      = TaxiGo
DESTINATION ?= platform=iOS Simulator,name=iPhone 16,OS=latest
CONFIG      ?= Debug

.PHONY: help project build test run clean open sim

help:
	@echo "TaxiGo — available targets:"
	@echo "  make project   Regenerate Xcode project from project.yml"
	@echo "  make build     Build $(SCHEME) for simulator"
	@echo "  make test      Run unit tests"
	@echo "  make run       Build + install + launch on simulator"
	@echo "  make sim       Boot an iPhone simulator (16 by default)"
	@echo "  make open      Open the generated Xcode project"
	@echo "  make clean     Remove build artifacts + generated project"

project: $(APP_NAME).xcodeproj/project.pbxproj
$(APP_NAME).xcodeproj/project.pbxproj: project.yml
	xcodegen generate --quiet

build: project
	xcodebuild \
	  -project $(APP_NAME).xcodeproj \
	  -scheme $(SCHEME) \
	  -configuration $(CONFIG) \
	  -destination '$(DESTINATION)' \
	  -quiet \
	  build | tail -20

test: project
	xcodebuild \
	  -project $(APP_NAME).xcodeproj \
	  -scheme $(SCHEME) \
	  -configuration $(CONFIG) \
	  -destination '$(DESTINATION)' \
	  -enableCodeCoverage YES \
	  test

sim:
	@xcrun simctl boot "iPhone 16" 2>/dev/null || true
	@open -a Simulator

run: project sim
	xcodebuild \
	  -project $(APP_NAME).xcodeproj \
	  -scheme $(SCHEME) \
	  -configuration $(CONFIG) \
	  -destination '$(DESTINATION)' \
	  -derivedDataPath build/DerivedData \
	  build
	@APP=build/DerivedData/Build/Products/$(CONFIG)-iphonesimulator/$(APP_NAME).app ; \
	xcrun simctl install booted $$APP && \
	xcrun simctl launch booted $$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' $$APP/Info.plist)

open: project
	open $(APP_NAME).xcodeproj

clean:
	rm -rf $(APP_NAME).xcodeproj build DerivedData
