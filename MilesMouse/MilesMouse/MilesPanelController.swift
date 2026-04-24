//
//  MilesPanelController.swift
//  MilesMouse
//
//  Created by Codex on 4/23/26.
//

import AppKit
import SwiftUI

final class MilesPanelController: NSWindowController {
    private let model = MilesMouseModel()
    private var mouseTimer: Timer?
    private var screenObserver: NSObjectProtocol?

    var isMilesVisible: Bool {
        window?.isVisible == true
    }

    init() {
        let panelSize = NSSize(width: 168, height: 188)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isOpaque = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.titleVisibility = .hidden

        super.init(window: panel)

        let hostingView = NSHostingView(
            rootView: ContentView(model: model) { [weak self] in
                self?.hideMiles()
            }
        )

        hostingView.frame = NSRect(origin: .zero, size: panelSize)
        panel.contentView = hostingView

        repositionAboveDock()
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
        repositionAboveDock()
        window?.orderFrontRegardless()
    }

    func hideMiles() {
        window?.orderOut(nil)
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
            self?.repositionAboveDock()
        }
    }

    private func repositionAboveDock() {
        guard let window, let screen = NSScreen.main ?? NSScreen.screens.first else {
            return
        }

        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let dockTopY = max(visibleFrame.minY, screenFrame.minY + 20)
        let x = screenFrame.midX - window.frame.width / 2
        let y = dockTopY + 8

        window.setFrameOrigin(NSPoint(x: round(x), y: round(y)))
    }
}
