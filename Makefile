APP = DesktopLabel
SRC = main.swift
BUNDLE = $(APP).app
EXECUTABLE = $(BUNDLE)/Contents/MacOS/$(APP)

all: $(BUNDLE)

$(BUNDLE): $(SRC) $(BUNDLE)/Contents/Info.plist
	swiftc -o $(EXECUTABLE) $(SRC) -framework Cocoa

run: $(BUNDLE)
	open $(BUNDLE)

clean:
	rm -f $(EXECUTABLE)

.PHONY: all run clean
