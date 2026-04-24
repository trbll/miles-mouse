//
//  AppDelegate.swift
//  MilesMouse
//
//  Created by Codex on 4/23/26.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: MilesPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        MilesPanelController.resetSavedPlacement()
        showMiles()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMiles()
        return true
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let isVisible = panelController?.isMilesVisible == true
        let visibilityItem = NSMenuItem(
            title: isVisible ? "Hide Miles" : "Show Miles",
            action: isVisible ? #selector(hideMilesFromMenu) : #selector(showMilesFromMenu),
            keyEquivalent: ""
        )

        visibilityItem.target = self
        menu.addItem(visibilityItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit MilesMouse", action: #selector(quitFromMenu), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func showMiles() {
        if panelController == nil {
            panelController = MilesPanelController()
        }

        panelController?.show()
    }

    @objc private func showMilesFromMenu() {
        showMiles()
    }

    @objc private func hideMilesFromMenu() {
        panelController?.hideMiles()
    }

    @objc private func quitFromMenu() {
        NSApplication.shared.terminate(nil)
    }
}
