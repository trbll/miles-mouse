//
//  MilesPanelController.swift
//  MilesMouse
//
//  Created by Codex on 4/23/26.
//

import AppKit
import SwiftUI

final class MilesPanelController: NSWindowController {
    private static let basePanelSize = NSSize(width: 168, height: 188)
    private static let customWindowOriginXKey = "MilesCustomWindowOriginX"
    private static let customWindowOriginYKey = "MilesCustomWindowOriginY"
    private static let visibleFramePadding: CGFloat = 8

    private let model = MilesMouseModel()
    private var selectedSize: MilesDisplaySize
    private var selectedDockPosition: MilesDockPosition
    private var customWindowOrigin: NSPoint?
    private var hostingView: RightClickHostingView<ContentView>?
    private var mouseTimer: Timer?
    private var screenObserver: NSObjectProtocol?

    var isMilesVisible: Bool {
        window?.isVisible == true
    }

    static func resetSavedPlacement() {
        MilesDisplaySize.resetSavedValue()
        MilesDockPosition.resetSavedValue()
        removeSavedCustomWindowOrigin()
    }

    init() {
        let initialSize = MilesDisplaySize.savedValue
        let panelSize = Self.panelSize(for: initialSize)

        selectedSize = initialSize
        selectedDockPosition = MilesDockPosition.savedValue
        customWindowOrigin = Self.savedCustomWindowOrigin

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isOpaque = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.titleVisibility = .hidden

        super.init(window: panel)

        let hostingView = RightClickHostingView(
            rootView: makeContentView(),
            onRightClick: { [weak self] event, view in
                guard let self else {
                    return
                }

                NSMenu.popUpContextMenu(self.makeMilesMenu(), with: event, for: view)
            }
        )

        hostingView.frame = NSRect(origin: .zero, size: panelSize)
        panel.contentView = hostingView
        self.hostingView = hostingView

        placeWindow()
        startMouseTracking()
        observeScreenChanges()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        mouseTimer?.invalidate()

        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    func show() {
        placeWindow()
        window?.orderFrontRegardless()
    }

    func hideMiles() {
        window?.orderOut(nil)
    }

    func makeMilesMenu() -> NSMenu {
        let menu = NSMenu()

        let hideItem = NSMenuItem(title: "Hide Miles", action: #selector(hideMilesFromMenu), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)
        menu.addItem(.separator())

        MilesDisplaySize.allCases.forEach { size in
            let item = NSMenuItem(title: size.menuTitle, action: #selector(selectSizeFromMenu(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = size.rawValue
            item.state = size == selectedSize ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        MilesDockPosition.allCases.forEach { position in
            let item = NSMenuItem(title: position.menuTitle, action: #selector(selectDockPositionFromMenu(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = position.rawValue
            item.state = customWindowOrigin == nil && position == selectedDockPosition ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Miles", action: #selector(quitMilesFromMenu), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func startMouseTracking() {
        mouseTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self, let window else {
                return
            }

            guard window.isVisible else {
                return
            }

            model.update(mouseLocation: NSEvent.mouseLocation, milesFrame: window.frame)
        }
    }

    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.placeWindow()
        }
    }

    private func makeContentView() -> ContentView {
        ContentView(
            model: model,
            displayScale: selectedSize.scale,
            onMoveDragStarted: { [weak self] mouseLocation in
                self?.beginWindowDrag(mouseLocation: mouseLocation)
            },
            onMoveDragChanged: { [weak self] mouseLocation in
                self?.updateWindowDrag(mouseLocation: mouseLocation)
            },
            onMoveDragEnded: { [weak self] in
                self?.endWindowDrag()
            }
        )
    }

    private func placeWindow() {
        guard let customWindowOrigin else {
            repositionAboveDock()
            return
        }

        let origin = clampedOrigin(customWindowOrigin)
        window?.setFrameOrigin(origin)
        self.customWindowOrigin = origin
        saveCustomWindowOrigin(origin)
    }

    private func repositionAboveDock() {
        guard let window, let screen = NSScreen.main ?? NSScreen.screens.first else {
            return
        }

        let visibleFrame = screen.visibleFrame
        let usableFrame = visibleFrame.insetBy(dx: Self.visibleFramePadding, dy: Self.visibleFramePadding)
        let x: CGFloat

        switch selectedDockPosition {
        case .left:
            x = usableFrame.minX + 16
        case .center:
            x = usableFrame.midX - window.frame.width / 2
        case .right:
            x = usableFrame.maxX - window.frame.width - 16
        }

        let y = usableFrame.minY

        window.setFrameOrigin(clampedOrigin(NSPoint(x: round(x), y: round(y))))
    }

    private func beginWindowDrag(mouseLocation: NSPoint) {
        updateWindowDrag(mouseLocation: mouseLocation)
    }

    private func updateWindowDrag(mouseLocation: NSPoint) {
        guard let window else {
            return
        }

        let origin = NSPoint(
            x: mouseLocation.x - window.frame.width / 2,
            y: mouseLocation.y - window.frame.height / 2
        )

        window.setFrameOrigin(clampedOrigin(origin))
    }

    private func endWindowDrag() {
        guard let window else {
            return
        }

        let origin = clampedOrigin(window.frame.origin)
        customWindowOrigin = origin
        saveCustomWindowOrigin(origin)
        window.setFrameOrigin(origin)
    }

    private func applySize(_ size: MilesDisplaySize) {
        guard selectedSize != size else {
            return
        }

        selectedSize = size
        selectedSize.save()

        guard let window else {
            return
        }

        let nextSize = Self.panelSize(for: size)
        window.setContentSize(nextSize)
        hostingView?.frame = NSRect(origin: .zero, size: nextSize)
        hostingView?.rootView = makeContentView()
        placeWindow()
    }

    private func applyDockPosition(_ position: MilesDockPosition) {
        selectedDockPosition = position
        selectedDockPosition.save()
        customWindowOrigin = nil
        removeCustomWindowOrigin()
        repositionAboveDock()
    }

    private static func panelSize(for size: MilesDisplaySize) -> NSSize {
        NSSize(width: basePanelSize.width * size.scale, height: basePanelSize.height * size.scale)
    }

    private func screen(for origin: NSPoint) -> NSScreen? {
        guard let window else {
            return NSScreen.main ?? NSScreen.screens.first
        }

        let frame = NSRect(origin: origin, size: window.frame.size)
        let center = NSPoint(x: frame.midX, y: frame.midY)
        return NSScreen.screens.first { $0.frame.contains(center) } ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func clampedOrigin(_ origin: NSPoint) -> NSPoint {
        guard let window else {
            return origin
        }

        guard let screen = screen(for: origin) else {
            return origin
        }

        let usableFrame = screen.visibleFrame.insetBy(dx: Self.visibleFramePadding, dy: Self.visibleFramePadding)
        let x = clampedAxisOrigin(
            origin.x,
            contentLength: window.frame.width,
            minimum: usableFrame.minX,
            maximum: usableFrame.maxX
        )
        let y = clampedAxisOrigin(
            origin.y,
            contentLength: window.frame.height,
            minimum: usableFrame.minY,
            maximum: usableFrame.maxY
        )

        return NSPoint(x: round(x), y: round(y))
    }

    private func clampedAxisOrigin(
        _ origin: CGFloat,
        contentLength: CGFloat,
        minimum: CGFloat,
        maximum: CGFloat
    ) -> CGFloat {
        let availableLength = maximum - minimum

        guard contentLength <= availableLength else {
            return minimum + (availableLength - contentLength) / 2
        }

        return min(max(origin, minimum), maximum - contentLength)
    }

    private static var savedCustomWindowOrigin: NSPoint? {
        let defaults = UserDefaults.standard

        guard
            defaults.object(forKey: customWindowOriginXKey) != nil,
            defaults.object(forKey: customWindowOriginYKey) != nil
        else {
            return nil
        }

        return NSPoint(
            x: defaults.double(forKey: customWindowOriginXKey),
            y: defaults.double(forKey: customWindowOriginYKey)
        )
    }

    private func saveCustomWindowOrigin(_ origin: NSPoint) {
        UserDefaults.standard.set(origin.x, forKey: Self.customWindowOriginXKey)
        UserDefaults.standard.set(origin.y, forKey: Self.customWindowOriginYKey)
    }

    private func removeCustomWindowOrigin() {
        Self.removeSavedCustomWindowOrigin()
    }

    private static func removeSavedCustomWindowOrigin() {
        UserDefaults.standard.removeObject(forKey: customWindowOriginXKey)
        UserDefaults.standard.removeObject(forKey: customWindowOriginYKey)
    }

    @objc private func hideMilesFromMenu() {
        hideMiles()
    }

    @objc private func selectSizeFromMenu(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let size = MilesDisplaySize(rawValue: rawValue)
        else {
            return
        }

        applySize(size)
    }

    @objc private func selectDockPositionFromMenu(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let position = MilesDockPosition(rawValue: rawValue)
        else {
            return
        }

        applyDockPosition(position)
    }

    @objc private func quitMilesFromMenu() {
        NSApplication.shared.terminate(nil)
    }
}

private final class RightClickHostingView<Content: View>: NSHostingView<Content> {
    private var onRightClick: (NSEvent, NSView) -> Void = { _, _ in }

    required init(rootView: Content) {
        super.init(rootView: rootView)
    }

    init(rootView: Content, onRightClick: @escaping (NSEvent, NSView) -> Void) {
        self.onRightClick = onRightClick
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick(event, self)
    }
}

private enum MilesDisplaySize: String, CaseIterable {
    private static let defaultsKey = "MilesDisplaySize"

    case xxs
    case xs
    case s
    case defaultSize
    case l
    case xl
    case xxl

    var menuTitle: String {
        switch self {
        case .xxs:
            return "XXS"
        case .xs:
            return "XS"
        case .s:
            return "S"
        case .defaultSize:
            return "Default"
        case .l:
            return "L"
        case .xl:
            return "XL"
        case .xxl:
            return "XXL"
        }
    }

    var scale: CGFloat {
        switch self {
        case .xxs:
            return 0.55
        case .xs:
            return 0.7
        case .s:
            return 0.85
        case .defaultSize:
            return 1
        case .l:
            return 1.25
        case .xl:
            return 2.4
        case .xxl:
            return 3.8
        }
    }

    static var savedValue: MilesDisplaySize {
        guard
            let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
            let size = MilesDisplaySize(rawValue: rawValue)
        else {
            return .defaultSize
        }

        return size
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.defaultsKey)
    }

    static func resetSavedValue() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}

private enum MilesDockPosition: String, CaseIterable {
    private static let defaultsKey = "MilesDockPosition"

    case left
    case center
    case right

    var menuTitle: String {
        switch self {
        case .left:
            return "Left"
        case .center:
            return "Center"
        case .right:
            return "Right"
        }
    }

    static var savedValue: MilesDockPosition {
        guard
            let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
            let position = MilesDockPosition(rawValue: rawValue)
        else {
            return .center
        }

        return position
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.defaultsKey)
    }

    static func resetSavedValue() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
