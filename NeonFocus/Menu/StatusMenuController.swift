import AppKit

@MainActor
final class StatusMenuController: NSObject, NSMenuDelegate {
    var onToggleEnabled: ((Bool) -> Void)?
    var onSettingsChanged: ((NeonFocusSettings) -> Void)?
    var onQuit: (() -> Void)?

    private(set) var isEnabled: Bool = true
    private(set) var settings = NeonFocusSettings.default
    private var statusItem: NSStatusItem?
    private var enabledItem: NSMenuItem?
    private var colorItems: [NeonFocusSettings.Color: NSMenuItem] = [:]
    private var thicknessItems: [NeonFocusSettings.Thickness: NSMenuItem] = [:]
    private var pulseSpeedItems: [NeonFocusSettings.PulseSpeed: NSMenuItem] = [:]
    private var glowItems: [NeonFocusSettings.GlowIntensity: NSMenuItem] = [:]
    private var vibrationItems: [NeonFocusSettings.Vibration: NSMenuItem] = [:]
    private var terminalAppItems: [NeonFocusSettings.TerminalApp: NSMenuItem] = [:]

    #if DEBUG
    private var debugStandaloneMenu: NSMenu?

    var debugMenu: NSMenu? { statusItem?.menu ?? debugStandaloneMenu }

    func debugInstallMenu(enabled: Bool, settings: NeonFocusSettings = .default) {
        uninstall()
        configure(enabled: enabled, settings: settings)
        debugStandaloneMenu = makeMenu(enabled: enabled)
        updateSettingsItemStates()
    }

    func debugPerformAction(for item: NSMenuItem) {
        guard let action = item.action else { return }
        NSApp.sendAction(action, to: item.target, from: item)
    }
    #endif

    func install(enabled: Bool, settings: NeonFocusSettings = .default) {
        uninstall()
        configure(enabled: enabled, settings: settings)

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(
                systemSymbolName: "circle.dashed",
                accessibilityDescription: "NeonFocus"
            )
            image?.isTemplate = true
            button.image = image
        }

        item.menu = makeMenu(enabled: enabled)
        statusItem = item
        updateSettingsItemStates()
    }

    func uninstall() {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
        enabledItem = nil
        colorItems = [:]
        thicknessItems = [:]
        pulseSpeedItems = [:]
        glowItems = [:]
        vibrationItems = [:]
        terminalAppItems = [:]
        #if DEBUG
        debugStandaloneMenu = nil
        #endif
    }

    private func configure(enabled: Bool, settings: NeonFocusSettings) {
        isEnabled = enabled
        self.settings = settings
    }

    private func makeMenu(enabled: Bool) -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        let enabledItem = NSMenuItem(
            title: "Enable NeonFocus",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabledItem.target = self
        enabledItem.state = enabled ? .on : .off
        menu.addItem(enabledItem)
        self.enabledItem = enabledItem

        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeColorMenu())
        menu.addItem(makeThicknessMenu())
        menu.addItem(makePulseSpeedMenu())
        menu.addItem(makeGlowMenu())
        menu.addItem(makeVibrationMenu())
        menu.addItem(makeTerminalAppsMenu())

        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(
            title: "Quit NeonFocus",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        enabledItem?.state = isEnabled ? .on : .off
        onToggleEnabled?(isEnabled)
    }

    @objc private func quitApp() {
        onQuit?()
    }

    @objc private func selectColor(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let color = NeonFocusSettings.Color(rawValue: rawValue)
        else { return }
        settings.color = color
        publishSettingsChange()
    }

    @objc private func selectThickness(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let thickness = NeonFocusSettings.Thickness(rawValue: rawValue)
        else { return }
        settings.thickness = thickness
        publishSettingsChange()
    }

    @objc private func selectPulseSpeed(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let pulseSpeed = NeonFocusSettings.PulseSpeed(rawValue: rawValue)
        else { return }
        settings.pulseSpeed = pulseSpeed
        publishSettingsChange()
    }

    @objc private func selectGlowIntensity(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let glowIntensity = NeonFocusSettings.GlowIntensity(rawValue: rawValue)
        else { return }
        settings.glowIntensity = glowIntensity
        publishSettingsChange()
    }

    @objc private func selectVibration(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let vibration = NeonFocusSettings.Vibration(rawValue: rawValue)
        else { return }
        settings.vibration = vibration
        publishSettingsChange()
    }

    @objc private func toggleTerminalApp(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let terminalApp = NeonFocusSettings.TerminalApp(rawValue: rawValue)
        else { return }

        if settings.trackedTerminalApps.contains(terminalApp) {
            settings.trackedTerminalApps.remove(terminalApp)
        } else {
            settings.trackedTerminalApps.insert(terminalApp)
        }
        publishSettingsChange()
    }

    private func makeColorMenu() -> NSMenuItem {
        let item = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Color")
        colorItems = Dictionary(
            uniqueKeysWithValues: NeonFocusSettings.Color.allCases.map { color in
                let menuItem = makeOptionItem(
                    title: color.title,
                    rawValue: color.rawValue,
                    action: #selector(selectColor)
                )
                submenu.addItem(menuItem)
                return (color, menuItem)
            }
        )
        item.submenu = submenu
        return item
    }

    private func makeThicknessMenu() -> NSMenuItem {
        let item = NSMenuItem(title: "Thickness", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Thickness")
        thicknessItems = Dictionary(
            uniqueKeysWithValues: NeonFocusSettings.Thickness.allCases.map { thickness in
                let menuItem = makeOptionItem(
                    title: thickness.title,
                    rawValue: thickness.rawValue,
                    action: #selector(selectThickness)
                )
                submenu.addItem(menuItem)
                return (thickness, menuItem)
            }
        )
        item.submenu = submenu
        return item
    }

    private func makePulseSpeedMenu() -> NSMenuItem {
        let item = NSMenuItem(title: "Pulse Speed", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Pulse Speed")
        pulseSpeedItems = Dictionary(
            uniqueKeysWithValues: NeonFocusSettings.PulseSpeed.allCases.map { pulseSpeed in
                let menuItem = makeOptionItem(
                    title: pulseSpeed.title,
                    rawValue: pulseSpeed.rawValue,
                    action: #selector(selectPulseSpeed)
                )
                submenu.addItem(menuItem)
                return (pulseSpeed, menuItem)
            }
        )
        item.submenu = submenu
        return item
    }

    private func makeGlowMenu() -> NSMenuItem {
        let item = NSMenuItem(title: "Glow", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Glow")
        glowItems = Dictionary(
            uniqueKeysWithValues: NeonFocusSettings.GlowIntensity.allCases.map { glowIntensity in
                let menuItem = makeOptionItem(
                    title: glowIntensity.title,
                    rawValue: glowIntensity.rawValue,
                    action: #selector(selectGlowIntensity)
                )
                submenu.addItem(menuItem)
                return (glowIntensity, menuItem)
            }
        )
        item.submenu = submenu
        return item
    }

    private func makeVibrationMenu() -> NSMenuItem {
        let item = NSMenuItem(title: "Vibration", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Vibration")
        vibrationItems = Dictionary(
            uniqueKeysWithValues: NeonFocusSettings.Vibration.allCases.map { vibration in
                let menuItem = makeOptionItem(
                    title: vibration.title,
                    rawValue: vibration.rawValue,
                    action: #selector(selectVibration)
                )
                submenu.addItem(menuItem)
                return (vibration, menuItem)
            }
        )
        item.submenu = submenu
        return item
    }

    private func makeTerminalAppsMenu() -> NSMenuItem {
        let item = NSMenuItem(title: "Terminal Apps", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Terminal Apps")
        terminalAppItems = Dictionary(
            uniqueKeysWithValues: NeonFocusSettings.TerminalApp.allCases.map { terminalApp in
                let menuItem = makeOptionItem(
                    title: terminalApp.title,
                    rawValue: terminalApp.rawValue,
                    action: #selector(toggleTerminalApp)
                )
                submenu.addItem(menuItem)
                return (terminalApp, menuItem)
            }
        )
        item.submenu = submenu
        return item
    }

    private func makeOptionItem(
        title: String,
        rawValue: String,
        action: Selector
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.representedObject = rawValue
        return item
    }

    private func publishSettingsChange() {
        updateSettingsItemStates()
        onSettingsChanged?(settings)
    }

    private func updateSettingsItemStates() {
        updateStates(items: colorItems, selected: settings.color)
        updateStates(items: thicknessItems, selected: settings.thickness)
        updateStates(items: pulseSpeedItems, selected: settings.pulseSpeed)
        updateStates(items: glowItems, selected: settings.glowIntensity)
        updateStates(items: vibrationItems, selected: settings.vibration)
        updateTerminalAppItemStates()
    }

    private func updateStates<Option: Hashable>(
        items: [Option: NSMenuItem],
        selected: Option
    ) {
        for (option, item) in items {
            item.state = option == selected ? .on : .off
        }
    }

    private func updateTerminalAppItemStates() {
        for (terminalApp, item) in terminalAppItems {
            item.state = settings.trackedTerminalApps.contains(terminalApp) ? .on : .off
        }
    }
}
