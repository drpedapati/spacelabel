APP = SpaceLabel
SRC = main.swift
BUNDLE = $(APP).app
EXECUTABLE = $(BUNDLE)/Contents/MacOS/$(APP)

all: $(BUNDLE)

$(BUNDLE): $(SRC) $(BUNDLE)/Contents/Info.plist
	@mkdir -p $(BUNDLE)/Contents/MacOS
	swiftc -O -o $(EXECUTABLE) $(SRC) -framework Cocoa

run: $(BUNDLE)
	open $(BUNDLE)

install: $(BUNDLE)
	cp -R $(BUNDLE) /Applications/

uninstall:
	rm -rf /Applications/$(BUNDLE)

clean:
	rm -rf $(BUNDLE)

.PHONY: all run install uninstall clean
