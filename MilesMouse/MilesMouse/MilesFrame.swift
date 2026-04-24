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
    case downLeft
    case downRight
    case down
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
        case .downLeft:
            return "DOWN LEFT"
        case .downRight:
            return "DOWN RIGHT"
        case .down:
            return "DOWN"
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
            return 3
        case .bark:
            return 1
        case .forward, .left, .right, .upLeft, .upRight, .up, .downLeft, .downRight, .down:
            return 1
        }
    }

    var animationInterval: TimeInterval {
        switch self {
        case .bark:
            return 0.45
        case .pet:
            return 1.8
        case .tilt:
            return 1.35
        case .forward, .left, .right, .upLeft, .upRight, .up, .downLeft, .downRight, .down:
            return 0.7
        }
    }

    var assetBaseName: String {
        switch self {
        case .forward:
            return "miles_alpha_forward"
        case .tilt:
            return "miles_alpha_tilt"
        case .left:
            return "miles_alpha_left"
        case .right:
            return "miles_alpha_right"
        case .upLeft:
            return "miles_alpha_up_left"
        case .upRight:
            return "miles_alpha_up_right"
        case .up:
            return "miles_alpha_up"
        case .downLeft:
            return "miles_alpha_down_left"
        case .downRight:
            return "miles_alpha_down_right"
        case .down:
            return "miles_alpha_down"
        case .pet:
            return "miles_alpha_pet"
        case .bark:
            return "miles_alpha_bark"
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

    var assetName: String {
        guard pose.frameCount > 1 else {
            return pose.assetBaseName
        }

        return "\(pose.assetBaseName)_\(variant + 1)"
    }
}
