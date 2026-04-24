//
//  MilesFrame.swift
//  MilesMouse
//
//  Created by Codex on 4/23/26.
//

import Foundation

enum MilesPose: String, CaseIterable, Equatable {
    case forward
    case tilt
    case left
    case right
    case upLeft
    case upRight
    case up
    case pet
    case bark

    var label: String {
        switch self {
        case .forward:
            return "FORWARD"
        case .tilt:
            return "TILT"
        case .left:
            return "LEFT"
        case .right:
            return "RIGHT"
        case .upLeft:
            return "UP LEFT"
        case .upRight:
            return "UP RIGHT"
        case .up:
            return "UP"
        case .pet:
            return "PET"
        case .bark:
            return "BARK"
        }
    }

    var frameCount: Int {
        switch self {
        case .tilt:
            return 2
        case .pet:
            return 4
        case .bark:
            return 2
        case .forward, .left, .right, .upLeft, .upRight, .up:
            return 1
        }
    }

    var animationInterval: TimeInterval {
        switch self {
        case .bark:
            return 0.12
        case .pet:
            return 0.16
        case .tilt:
            return 0.42
        case .forward, .left, .right, .upLeft, .upRight, .up:
            return 0.35
        }
    }
}

struct MilesFrame: Equatable {
    let pose: MilesPose
    let variant: Int

    init(pose: MilesPose, variant: Int = 0) {
        self.pose = pose
        self.variant = min(max(variant, 0), pose.frameCount - 1)
    }

    var label: String {
        guard pose.frameCount > 1 else {
            return pose.label
        }

        return "\(pose.label) \(variant + 1)"
    }
}
