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

    private let initialPetTravelThreshold: CGFloat = 45
    private let petVariantTravelInterval: CGFloat = 320
    private let tiltDistanceThreshold: CGFloat = 110
    private let upwardLookThreshold: CGFloat = 150
    private let downwardLookThreshold: CGFloat = -65
    private let sideLookThreshold: CGFloat = 70

    private var currentPose: MilesPose
    private var currentVariant = 0
    private var lastVariantAdvance = Date.distantPast
    private var lastPetVariantAdvance = Date.distantPast
    private var lastPetTravelAdvance: CGFloat = 0
    private var lastTiltUpdate = Date.distantPast
    private var tiltProgress: TimeInterval = 0
    private var isPetting = false
    private var transientPose: MilesPose?
    private var transientExpiresAt = Date.distantPast

    init(currentFrame: MilesFrame = MilesFrame(pose: .forward)) {
        self.currentFrame = currentFrame
        currentPose = currentFrame.pose
        currentVariant = currentFrame.variant
    }

    func update(mouseLocation: NSPoint, milesFrame: NSRect, now: Date = .now) {
        guard !isPetting else {
            return
        }

        if now >= transientExpiresAt {
            transientPose = nil
        }

        let faceCenter = NSPoint(x: milesFrame.midX, y: milesFrame.midY + 24)
        let dx = mouseLocation.x - faceCenter.x
        let dy = mouseLocation.y - faceCenter.y
        let distance = hypot(dx, dy)

        cursorDistance = distance

        if let transientPose {
            resetTiltProgress()
            applyPose(transientPose, now: now)
            return
        }

        let isMouseInsideWindow = milesFrame.contains(mouseLocation)
        let nextPose = directionPose(dx: dx, dy: dy, distance: distance, isMouseInsideWindow: isMouseInsideWindow)

        guard nextPose != .tilt else {
            applyTilt(distance: distance, now: now)
            return
        }

        resetTiltProgress()
        applyPose(nextPose, now: now)
    }

    func triggerBark() {
        isPetting = false
        setTransientPose(.bark, duration: 0.8)
    }

    func beginPetting(now: Date = .now) {
        isPetting = true
        resetTiltProgress()
        lastPetVariantAdvance = now
        lastPetTravelAdvance = 0
        lastVariantAdvance = now
    }

    func updatePetting(travelDistance: CGFloat, elapsed: TimeInterval, now: Date = .now) {
        guard isPetting, travelDistance >= initialPetTravelThreshold else {
            return
        }

        if currentPose != .pet {
            setPose(.pet, variant: randomPetVariant(), now: now)
            lastPetVariantAdvance = now
            lastPetTravelAdvance = travelDistance
            return
        }

        let hasPettedEnoughMore = travelDistance - lastPetTravelAdvance >= petVariantTravelInterval
        let hasWaitedLongEnough = now.timeIntervalSince(lastPetVariantAdvance) >= petFrameInterval(elapsed: elapsed)

        guard hasPettedEnoughMore && hasWaitedLongEnough else {
            return
        }

        setPose(.pet, variant: randomPetVariant(excluding: currentVariant), now: now)
        lastPetVariantAdvance = now
        lastPetTravelAdvance = travelDistance
    }

    func endPetting(now: Date = .now) {
        isPetting = false
        lastPetVariantAdvance = .distantPast
        lastPetTravelAdvance = 0
        setPose(.forward, variant: 0, now: now)
    }

    private func directionPose(dx: CGFloat, dy: CGFloat, distance: CGFloat, isMouseInsideWindow: Bool) -> MilesPose {
        if isMouseInsideWindow && distance < tiltDistanceThreshold {
            return .tilt
        }

        if dy > upwardLookThreshold {
            if dx < -sideLookThreshold {
                return .upLeft
            }

            if dx > sideLookThreshold {
                return .upRight
            }

            return .up
        }

        if dy < downwardLookThreshold {
            if dx < -sideLookThreshold {
                return .downLeft
            }

            if dx > sideLookThreshold {
                return .downRight
            }

            return .down
        }

        if dx < -sideLookThreshold {
            return .left
        }

        if dx > sideLookThreshold {
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

    private func applyTilt(distance: CGFloat, now: Date) {
        if currentPose != .tilt {
            tiltProgress = 0
            lastTiltUpdate = now
            setPose(.tilt, variant: 0, now: now)
            return
        }

        let elapsed = max(0, now.timeIntervalSince(lastTiltUpdate))
        lastTiltUpdate = now

        let closeness = max(0, min(1, (tiltDistanceThreshold - distance) / tiltDistanceThreshold))
        let proximityMultiplier = 0.55 + closeness
        tiltProgress += elapsed * proximityMultiplier

        let variant = Int(tiltProgress / MilesPose.tilt.animationInterval) % MilesPose.tilt.frameCount
        setPose(.tilt, variant: variant, now: now)
    }

    private func applyPose(_ pose: MilesPose, now: Date) {
        if currentPose != pose {
            setPose(pose, variant: 0, now: now)
            return
        }

        if pose.frameCount > 1 && now.timeIntervalSince(lastVariantAdvance) >= pose.animationInterval {
            currentVariant = (currentVariant + 1) % pose.frameCount
            lastVariantAdvance = now
            setFrame(MilesFrame(pose: pose, variant: currentVariant))
        }
    }

    private func setPose(_ pose: MilesPose, variant: Int, now: Date) {
        currentPose = pose
        currentVariant = min(max(variant, 0), pose.frameCount - 1)
        lastVariantAdvance = now
        setFrame(MilesFrame(pose: pose, variant: currentVariant))
    }

    private func resetTiltProgress() {
        tiltProgress = 0
        lastTiltUpdate = .distantPast
    }

    private func petFrameInterval(elapsed: TimeInterval) -> TimeInterval {
        max(1.45, MilesPose.pet.animationInterval - min(0.18, elapsed * 0.015))
    }

    private func randomPetVariant(excluding excludedVariant: Int? = nil) -> Int {
        guard MilesPose.pet.frameCount > 1 else {
            return 0
        }

        var variant = Int.random(in: 0..<MilesPose.pet.frameCount)

        if let excludedVariant, MilesPose.pet.frameCount > 1 {
            while variant == excludedVariant {
                variant = Int.random(in: 0..<MilesPose.pet.frameCount)
            }
        }

        return variant
    }

    private func setFrame(_ frame: MilesFrame) {
        guard currentFrame != frame else {
            return
        }

        currentFrame = frame
    }
}
