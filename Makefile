APP = DesktopLabel
SRC = main.swift

all: $(APP)

$(APP): $(SRC)
	swiftc -o $(APP) $(SRC) -framework Cocoa

run: $(APP)
	./$(APP)

clean:
	rm -f $(APP)

.PHONY: all run clean
