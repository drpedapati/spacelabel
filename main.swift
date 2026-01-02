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
    override var canBecomeMain: Bool { return false }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.isMovableByWindowBackground = true
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = true
        self.hidesOnDeactivate = false
    }
}

class ClickableLabel: NSTextField {
    var onClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSTextFieldDelegate {
    var window: NSWindow!
    var label: ClickableLabel!
    var editField: NSTextField!
    var resetButton: NSButton!
    var containerView: NSView!
    var currentSpaceID: Int = 0

    // Colors
    let unlabeledColor = NSColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 0.85)  // Tasteful red
    let labeledColor = NSColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 0.85)    // Green

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

        label.stringValue = customLabel ?? String(currentSpaceID)
        window.backgroundColor = isLabeled ? labeledColor : unlabeledColor
        resetButton.isHidden = !isLabeled
    }

    func showEditField() {
        label.isHidden = true
        resetButton.isHidden = true
        editField.isHidden = false
        editField.stringValue = label.stringValue
        window.makeFirstResponder(editField)
        editField.selectText(nil)
    }

    func hideEditField() {
        editField.isHidden = true
        label.isHidden = false
        updateLabel()
    }

    func saveCurrentEdit() {
        let newName = editField.stringValue.trimmingCharacters(in: .whitespaces)
        if !newName.isEmpty && newName != String(currentSpaceID) {
            saveLabel(spaceID: currentSpaceID, name: newName)
        }
        hideEditField()
    }

    @objc func resetClicked() {
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
            contentRect: NSRect(x: 100, y: 100, width: 180, height: 50),
            styleMask: [.borderless, .nonactivatingPanel],
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

        // Container view
        containerView = NSView(frame: NSRect(x: 0, y: 0, width: 180, height: 50))
        window.contentView?.addSubview(containerView)

        // Create the clickable label
        label = ClickableLabel(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.alignment = .center
        label.frame = NSRect(x: 10, y: 10, width: 140, height: 30)
        label.onClick = { [weak self] in
            self?.showEditField()
        }
        containerView.addSubview(label)

        // Create the edit field (hidden by default)
        editField = NSTextField(frame: NSRect(x: 10, y: 10, width: 140, height: 30))
        editField.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        editField.alignment = .center
        editField.isHidden = true
        editField.delegate = self
        editField.focusRingType = .none
        containerView.addSubview(editField)

        // Create reset button
        resetButton = NSButton(frame: NSRect(x: 155, y: 15, width: 20, height: 20))
        resetButton.title = "×"
        resetButton.bezelStyle = .inline
        resetButton.isBordered = false
        resetButton.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        resetButton.contentTintColor = .white
        resetButton.target = self
        resetButton.action = #selector(resetClicked)
        resetButton.isHidden = true
        containerView.addSubview(resetButton)

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

        app.mainMenu = mainMenu
    }

    @objc func spaceDidChange(_ notification: Notification) {
        hideEditField()
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
