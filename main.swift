// SpaceLabel - A floating overlay for naming macOS Spaces
// Copyright (c) 2025 Ernie Pedapati
// https://github.com/drpedapati/spacelabel
// MIT License

import Cocoa

// Private CoreGraphics API for Space detection
@_silgen_name("_CGSDefaultConnection")
func _CGSDefaultConnection() -> Int32

@_silgen_name("CGSGetActiveSpace")
func CGSGetActiveSpace(_ connection: Int32) -> Int

private let kSpaceLabelsKey = "SpaceLabels"

private class EditableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSTextFieldDelegate, NSWindowDelegate {
    private var window: EditableWindow!
    private var visualEffectView: NSVisualEffectView!
    private var colorOverlay: NSView!
    private var statusDot: NSView!
    private var label: NSTextField!
    private var editButton: NSButton!
    private var editField: NSTextField!
    private var clearButton: NSButton!
    private var currentSpaceID: Int = 0

    private func getSpaceID() -> Int {
        CGSGetActiveSpace(_CGSDefaultConnection())
    }

    // MARK: - Label Storage

    private func saveLabel(spaceID: Int, name: String) {
        var labels = UserDefaults.standard.dictionary(forKey: kSpaceLabelsKey) as? [String: String] ?? [:]
        labels[String(spaceID)] = name
        UserDefaults.standard.set(labels, forKey: kSpaceLabelsKey)
    }

    private func getLabel(spaceID: Int) -> String? {
        let labels = UserDefaults.standard.dictionary(forKey: kSpaceLabelsKey) as? [String: String] ?? [:]
        return labels[String(spaceID)]
    }

    private func removeLabel(spaceID: Int) {
        var labels = UserDefaults.standard.dictionary(forKey: kSpaceLabelsKey) as? [String: String] ?? [:]
        labels.removeValue(forKey: String(spaceID))
        UserDefaults.standard.set(labels, forKey: kSpaceLabelsKey)
    }

    // MARK: - UI Updates

    private func updateDisplay() {
        currentSpaceID = getSpaceID()
        let customLabel = getLabel(spaceID: currentSpaceID)
        let isLabeled = customLabel != nil

        label.stringValue = (customLabel ?? "Space \(currentSpaceID)").uppercased()

        // Instant updates - no animation delay
        statusDot.layer?.backgroundColor = isLabeled
            ? NSColor.systemGreen.cgColor
            : NSColor.tertiaryLabelColor.cgColor
        colorOverlay.layer?.backgroundColor = isLabeled
            ? NSColor.systemGreen.withAlphaComponent(0.45).cgColor
            : NSColor.systemRed.withAlphaComponent(0.40).cgColor
        clearButton.isHidden = !isLabeled
        editButton.isHidden = isLabeled
    }

    @objc func editClicked() {
        label.isHidden = true
        editButton.isHidden = true
        clearButton.isHidden = true
        statusDot.isHidden = true

        editField.isHidden = false
        editField.stringValue = getLabel(spaceID: currentSpaceID) ?? ""

        // Full activation for dictation
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        // Ensure first responder is set after a brief delay
        DispatchQueue.main.async {
            self.window.makeFirstResponder(self.editField)
            self.editField.currentEditor()?.selectAll(nil)
        }
    }

    private func hideEditField() {
        editField.isHidden = true
        label.isHidden = false
        editButton.isHidden = false
        statusDot.isHidden = false
        updateDisplay()
    }

    private func saveCurrentEdit() {
        let newName = editField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newName.isEmpty {
            saveLabel(spaceID: currentSpaceID, name: newName)
            showSaveAnimation()
        }
        hideEditField()
    }

    private func showSaveAnimation() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            context.allowsImplicitAnimation = true
            visualEffectView.layer?.setAffineTransform(CGAffineTransform(scaleX: 1.02, y: 1.02))
        }, completionHandler: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.1
                context.allowsImplicitAnimation = true
                self.visualEffectView.layer?.setAffineTransform(.identity)
            }
        })
    }

    @objc func clearClicked() {
        removeLabel(spaceID: currentSpaceID)
        updateDisplay()
    }

    // MARK: - NSTextFieldDelegate

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            saveCurrentEdit()
            return true
        } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            hideEditField()
            return true
        }
        return false
    }

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
        setupViews()
        setupMenu()
        updateDisplay()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        window.orderFrontRegardless()
    }

    private func setupWindow() {
        // Position at bottom-left, at dock level
        let margin: CGFloat = 10
        let windowWidth: CGFloat = 220
        let windowHeight: CGFloat = 44
        let xPos = margin
        let yPos = margin

        // Use custom NSWindow subclass that can become key
        window = EditableWindow(
            contentRect: NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.hasShadow = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
    }

    private func setupViews() {
        // Visual effect as content view
        visualEffectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 220, height: 44))
        visualEffectView.material = .hudWindow
        visualEffectView.state = .active
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 10
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.layer?.borderWidth = 0.5
        visualEffectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        window.contentView = visualEffectView

        // Color overlay for tinting
        colorOverlay = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 44))
        colorOverlay.wantsLayer = true
        colorOverlay.layer?.cornerRadius = 10
        visualEffectView.addSubview(colorOverlay)

        // Status dot - vertically centered
        statusDot = NSView(frame: NSRect(x: 14, y: 17, width: 10, height: 10))
        statusDot.wantsLayer = true
        statusDot.layer?.cornerRadius = 5
        statusDot.layer?.backgroundColor = NSColor.tertiaryLabelColor.cgColor
        visualEffectView.addSubview(statusDot)

        // Label (double-click to edit) - larger font, vertically centered
        label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .labelColor
        label.alignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.frame = NSRect(x: 30, y: 11, width: 156, height: 22)

        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(editClicked))
        doubleClick.numberOfClicksRequired = 2
        label.addGestureRecognizer(doubleClick)

        visualEffectView.addSubview(label)

        // Edit button
        editButton = NSButton(frame: NSRect(x: 188, y: 10, width: 24, height: 24))
        editButton.bezelStyle = .inline
        editButton.isBordered = false
        if let img = NSImage(systemSymbolName: "pencil", accessibilityDescription: "Edit") {
            editButton.image = img.withSymbolConfiguration(.init(pointSize: 12, weight: .medium))
        }
        editButton.contentTintColor = .secondaryLabelColor
        editButton.target = self
        editButton.action = #selector(editClicked)
        editButton.toolTip = "Rename space"
        visualEffectView.addSubview(editButton)

        // Clear button
        clearButton = NSButton(frame: NSRect(x: 188, y: 10, width: 24, height: 24))
        clearButton.bezelStyle = .inline
        clearButton.isBordered = false
        if let img = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Clear") {
            clearButton.image = img.withSymbolConfiguration(.init(pointSize: 13, weight: .medium))
        }
        clearButton.contentTintColor = .secondaryLabelColor
        clearButton.target = self
        clearButton.action = #selector(clearClicked)
        clearButton.toolTip = "Clear name"
        clearButton.isHidden = true
        visualEffectView.addSubview(clearButton)

        // Edit field
        editField = NSTextField(frame: NSRect(x: 8, y: 8, width: 204, height: 28))
        editField.font = NSFont.systemFont(ofSize: 15, weight: .medium)
        editField.alignment = .center
        editField.placeholderString = "Enter name..."
        editField.isHidden = true
        editField.delegate = self
        editField.focusRingType = .default
        editField.bezelStyle = .roundedBezel
        editField.drawsBackground = true
        editField.isEditable = true
        editField.isSelectable = true
        editField.usesSingleLineMode = true
        editField.allowsEditingTextAttributes = false
        editField.importsGraphics = false
        visualEffectView.addSubview(editField)
    }

    private func setupMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "About SpaceLabel", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit SpaceLabel", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu

        // Edit menu (for clipboard and dictation support)
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
    }

    @objc func spaceDidChange(_ notification: Notification) {
        if !editField.isHidden {
            hideEditField()
        }
        updateDisplay()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// Launch
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
