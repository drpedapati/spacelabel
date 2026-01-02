import Cocoa

// Private API declarations for getting Space ID
@_silgen_name("_CGSDefaultConnection")
func _CGSDefaultConnection() -> Int32

@_silgen_name("CGSGetActiveSpace")
func CGSGetActiveSpace(_ connection: Int32) -> Int

// Storage keys
let kSpaceLabelsKey = "SpaceLabels"

class MovableWindow: NSPanel {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.isMovableByWindowBackground = true
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSTextFieldDelegate, NSWindowDelegate {
    var window: NSWindow!
    var label: NSTextField!
    var editButton: NSButton!
    var editField: NSTextField!
    var clearButton: NSButton!
    var containerView: NSView!
    var currentSpaceID: Int = 0

    // Accessible colors (gray/blue instead of red/green)
    let unlabeledColor = NSColor(white: 0.25, alpha: 0.9)  // Neutral dark gray
    let labeledColor = NSColor(red: 0.2, green: 0.45, blue: 0.75, alpha: 0.9)  // Blue

    func getSpaceID() -> Int {
        let connection = _CGSDefaultConnection()
        return CGSGetActiveSpace(connection)
    }

    // MARK: - Label Storage

    func saveLabel(spaceID: Int, name: String) {
        var labels = UserDefaults.standard.dictionary(forKey: kSpaceLabelsKey) as? [String: String] ?? [:]
        labels[String(spaceID)] = name
        UserDefaults.standard.set(labels, forKey: kSpaceLabelsKey)
    }

    func getLabel(spaceID: Int) -> String? {
        let labels = UserDefaults.standard.dictionary(forKey: kSpaceLabelsKey) as? [String: String] ?? [:]
        return labels[String(spaceID)]
    }

    func removeLabel(spaceID: Int) {
        var labels = UserDefaults.standard.dictionary(forKey: kSpaceLabelsKey) as? [String: String] ?? [:]
        labels.removeValue(forKey: String(spaceID))
        UserDefaults.standard.set(labels, forKey: kSpaceLabelsKey)
    }

    func hasCustomLabel(spaceID: Int) -> Bool {
        return getLabel(spaceID: spaceID) != nil
    }

    // MARK: - UI Updates

    func updateLabel() {
        currentSpaceID = getSpaceID()
        let customLabel = getLabel(spaceID: currentSpaceID)
        let isLabeled = customLabel != nil

        // Show "Space #" for unlabeled, custom name for labeled
        label.stringValue = customLabel ?? "Space \(currentSpaceID)"

        // Update background color
        window.backgroundColor = isLabeled ? labeledColor : unlabeledColor

        // Show clear button only when labeled
        clearButton.isHidden = !isLabeled
    }

    @objc func editClicked() {
        label.isHidden = true
        editButton.isHidden = true
        clearButton.isHidden = true
        editField.isHidden = false

        // Pre-fill with current custom label or empty for new
        let customLabel = getLabel(spaceID: currentSpaceID)
        editField.stringValue = customLabel ?? ""

        // Activate app fully for dictation support
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(editField)
        editField.selectText(nil)
    }

    func hideEditField() {
        editField.isHidden = true
        label.isHidden = false
        editButton.isHidden = false
        updateLabel()
    }

    func saveCurrentEdit() {
        let newName = editField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newName.isEmpty {
            saveLabel(spaceID: currentSpaceID, name: newName)
            flashConfirmation()
        }
        hideEditField()
    }

    func flashConfirmation() {
        // Brief flash to confirm save
        let originalColor = window.backgroundColor
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            window.animator().backgroundColor = NSColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 0.9)
        }, completionHandler: {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                self.window.animator().backgroundColor = originalColor
            })
        })
    }

    @objc func clearClicked() {
        removeLabel(spaceID: currentSpaceID)
        updateLabel()
    }

    // MARK: - NSTextFieldDelegate

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            // Enter pressed - save
            saveCurrentEdit()
            return true
        } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            // Escape pressed - cancel
            hideEditField()
            return true
        }
        return false
    }

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create a borderless, movable window
        window = MovableWindow(
            contentRect: NSRect(x: 100, y: 100, width: 220, height: 44),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Configure window properties
        window.isOpaque = false
        window.backgroundColor = unlabeledColor
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.animationBehavior = .none
        window.ignoresMouseEvents = false
        window.delegate = self

        // Rounded corners
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 8
        window.contentView?.layer?.masksToBounds = true

        // Container view
        containerView = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 44))
        window.contentView?.addSubview(containerView)

        // Create the label (not clickable - just displays text)
        label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.alignment = .center
        label.frame = NSRect(x: 30, y: 7, width: 160, height: 30)
        containerView.addSubview(label)

        // Create small edit button (pencil icon)
        editButton = NSButton(frame: NSRect(x: 4, y: 10, width: 24, height: 24))
        editButton.bezelStyle = .inline
        editButton.isBordered = false
        editButton.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: "Edit")
        editButton.contentTintColor = .white
        editButton.target = self
        editButton.action = #selector(editClicked)
        editButton.toolTip = "Rename this space"
        containerView.addSubview(editButton)

        // Create the edit field (hidden by default)
        editField = NSTextField(frame: NSRect(x: 8, y: 7, width: 204, height: 30))
        editField.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        editField.alignment = .center
        editField.placeholderString = "Enter name... (Enter=save, Esc=cancel)"
        editField.isHidden = true
        editField.delegate = self
        editField.bezelStyle = .roundedBezel
        containerView.addSubview(editField)

        // Create clear button
        clearButton = NSButton(frame: NSRect(x: 190, y: 10, width: 24, height: 24))
        clearButton.bezelStyle = .inline
        clearButton.isBordered = false
        clearButton.image = NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: "Clear")
        clearButton.contentTintColor = .white
        clearButton.target = self
        clearButton.action = #selector(clearClicked)
        clearButton.toolTip = "Clear custom name"
        clearButton.isHidden = true
        containerView.addSubview(clearButton)

        // Update label with current space
        updateLabel()

        // Listen for space changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        // Show the window
        window.orderFrontRegardless()

        // Create menu with Quit option
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu

        NSApp.mainMenu = mainMenu
    }

    @objc func spaceDidChange(_ notification: Notification) {
        if !editField.isHidden {
            hideEditField()
        }
        updateLabel()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// Create and run the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
