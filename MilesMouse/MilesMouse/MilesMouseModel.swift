//
//  MilesMouseModel.swift
//  MilesMouse
//
//  Created by Codex on 4/23/26.
//

import AppKit
import Foundation

final class MilesMouseModel: ObservableObject {
    @Published private(set) var currentFrame: MilesFrame
    @Published private(set) var cursorDistance: CGFloat = 0

    private var currentPose: MilesPose
    private var currentVariant = 0
    private var lastVariantAdvance = Date.distantPast
    private var transientPose: MilesPose?
    private var transientExpiresAt = Date.distantPast

    init(currentFrame: MilesFrame = MilesFrame(pose: .forward)) {
        self.currentFrame = currentFrame
        currentPose = currentFrame.pose
        currentVariant = currentFrame.variant
    }

    func update(mouseLocation: NSPoint, milesFrame: NSRect, now: Date = .now) {
        if now >= transientExpiresAt {
            transientPose = nil
        }

        let faceCenter = NSPoint(x: milesFrame.midX, y: milesFrame.midY + 24)
        let dx = mouseLocation.x - faceCenter.x
        let dy = mouseLocation.y - faceCenter.y
        let distance = hypot(dx, dy)

        cursorDistance = distance
        let nextPose = transientPose ?? directionPose(dx: dx, dy: dy, distance: distance)
        applyPose(nextPose, now: now)
    }

    func triggerBark() {
        setTransientPose(.bark, duration: 0.5)
    }

    func triggerPet() {
        setTransientPose(.pet, duration: 0.65)
    }

    private func directionPose(dx: CGFloat, dy: CGFloat, distance: CGFloat) -> MilesPose {
        if distance < 80 {
            return .tilt
        }

        if dy > 150 {
            if dx < -70 {
                return .upLeft
            }

            if dx > 70 {
                return .upRight
            }

            return .up
        }

        if dx < -70 {
            return .left
        }

        if dx > 70 {
            return .right
        }

        return .forward
    }

    private func setTransientPose(_ pose: MilesPose, duration: TimeInterval) {
        let wasAlreadyActive = transientPose == pose && Date() < transientExpiresAt
        transientPose = pose
        transientExpiresAt = Date().addingTimeInterval(duration)

        if wasAlreadyActive {
            return
        }

        applyPose(pose, now: .now)
    }

    private func applyPose(_ pose: MilesPose, now: Date) {
        if currentPose != pose {
            currentPose = pose
            currentVariant = 0
            lastVariantAdvance = now
            setFrame(MilesFrame(pose: pose, variant: currentVariant))
            return
        }

        if pose.frameCount > 1 && now.timeIntervalSince(lastVariantAdvance) >= pose.animationInterval {
            currentVariant = (currentVariant + 1) % pose.frameCount
            lastVariantAdvance = now
            setFrame(MilesFrame(pose: pose, variant: currentVariant))
        }
    }

    private func setFrame(_ frame: MilesFrame) {
        guard currentFrame != frame else {
            return
        }

        currentFrame = frame
    }
}
