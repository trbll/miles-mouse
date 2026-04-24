//
//  ContentView.swift
//  MilesMouse
//
//  Created by Bell, Tyler R on 4/23/26.
//

import AppKit
import SwiftUI

struct ContentView: View {
    private static let petTimer = Timer.publish(every: 1.0 / 15.0, on: .main, in: .common).autoconnect()
    private static let baseSize = CGSize(width: 168, height: 188)
    private static let freeDragThreshold: CGFloat = 140
    private static let freeDragMinimumDuration: TimeInterval = 0.32

    @ObservedObject var model: MilesMouseModel
    let displayScale: CGFloat
    let onMoveDragStarted: (NSPoint) -> Void
    let onMoveDragChanged: (NSPoint) -> Void
    let onMoveDragEnded: () -> Void

    @State private var isBarking = false
    @State private var isMovingWindow = false
    @State private var petOffset: CGSize = .zero
    @State private var petTravelDistance: CGFloat = 0
    @State private var petStartedAt: Date?
    @State private var previousPetLocation: CGPoint?

    init(
        model: MilesMouseModel,
        displayScale: CGFloat = 1,
        onMoveDragStarted: @escaping (NSPoint) -> Void = { _ in },
        onMoveDragChanged: @escaping (NSPoint) -> Void = { _ in },
        onMoveDragEnded: @escaping () -> Void = {}
    ) {
        self.model = model
        self.displayScale = displayScale
        self.onMoveDragStarted = onMoveDragStarted
        self.onMoveDragChanged = onMoveDragChanged
        self.onMoveDragEnded = onMoveDragEnded
    }

    var body: some View {
        ZStack {
            MilesFrameView(frame: model.currentFrame, isBarking: isBarking)
                .offset(petOffset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged(updatePetDrag)
                        .onEnded { _ in
                            endPetDrag()
                        }
                )
                .onTapGesture {
                    triggerBark()
                }
        }
        .frame(width: Self.baseSize.width, height: Self.baseSize.height)
        .scaleEffect(displayScale)
        .frame(width: Self.baseSize.width * displayScale, height: Self.baseSize.height * displayScale)
        .background(.clear)
        .contentShape(Rectangle())
        .onReceive(Self.petTimer) { now in
            updatePetProgress(now: now)
        }
    }

    private func triggerBark() {
        model.triggerBark()

        withAnimation(.spring(response: 0.16, dampingFraction: 0.45)) {
            isBarking = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.62)) {
                isBarking = false
            }
        }
    }

    private func updatePetDrag(_ value: DragGesture.Value) {
        let now = Date.now
        let dragDistance = hypot(value.translation.width, value.translation.height)

        if petStartedAt == nil {
            petStartedAt = now
            model.beginPetting(now: now)
        }

        if isMovingWindow {
            onMoveDragChanged(NSEvent.mouseLocation)
            return
        }

        let petElapsed = now.timeIntervalSince(petStartedAt ?? now)
        let shouldSnapFree = dragDistance >= Self.freeDragThreshold && petElapsed >= Self.freeDragMinimumDuration

        if shouldSnapFree {
            isMovingWindow = true
            model.endPetting(now: now)
            previousPetLocation = nil
            petTravelDistance = 0

            withAnimation(.spring(response: 0.26, dampingFraction: 0.7)) {
                petOffset = .zero
            }

            onMoveDragStarted(NSEvent.mouseLocation)
            onMoveDragChanged(NSEvent.mouseLocation)
            return
        }

        if let previousPetLocation {
            let dx = value.location.x - previousPetLocation.x
            let dy = value.location.y - previousPetLocation.y
            petTravelDistance += hypot(dx, dy)
        }

        previousPetLocation = value.location
        withAnimation(.interactiveSpring(response: 0.24, dampingFraction: 0.62)) {
            petOffset = limitedOffset(from: value.translation)
        }

        updatePetProgress(now: .now)
    }

    private func endPetDrag() {
        if isMovingWindow {
            onMoveDragEnded()
        } else {
            model.endPetting()
        }

        isMovingWindow = false
        petTravelDistance = 0
        petStartedAt = nil
        previousPetLocation = nil

        withAnimation(.spring(response: 0.38, dampingFraction: 0.48)) {
            petOffset = .zero
        }
    }

    private func updatePetProgress(now: Date) {
        guard let petStartedAt else {
            return
        }

        model.updatePetting(
            travelDistance: petTravelDistance,
            elapsed: now.timeIntervalSince(petStartedAt),
            now: now
        )
    }

    private func limitedOffset(from translation: CGSize) -> CGSize {
        let maxDistance: CGFloat = 12
        let dampedTranslation = CGSize(width: translation.width * 0.35, height: translation.height * 0.35)
        let distance = hypot(dampedTranslation.width, dampedTranslation.height)

        guard distance > maxDistance else {
            return dampedTranslation
        }

        let scale = maxDistance / distance
        return CGSize(width: dampedTranslation.width * scale, height: dampedTranslation.height * scale)
    }
}

private struct MilesFrameView: View {
    let frame: MilesFrame
    let isBarking: Bool

    var body: some View {
        if let image = NSImage(named: frame.assetName) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 154, height: 154)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .scaleEffect(isBarking ? 1.16 : 1.0, anchor: .center)
                .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
                .accessibilityLabel("Miles frame \(frame.label)")
        } else {
            PlaceholderMilesFrame(frame: frame)
                .scaleEffect(isBarking ? 1.16 : 1.0, anchor: .center)
        }
    }
}

private struct PlaceholderMilesFrame: View {
    let frame: MilesFrame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.7), lineWidth: 3)
                )

            VStack(spacing: 8) {
                Text(frame.label)
                    .font(.system(size: frame.label.count > 6 ? 25 : 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.58)

                Text("MILES")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(14)
        }
        .frame(width: 142, height: 142)
        .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
        .accessibilityLabel("Miles frame \(frame.label)")
    }

    private var backgroundColor: Color {
        switch frame.pose {
        case .forward:
            return Color(red: 0.17, green: 0.43, blue: 0.72)
        case .tilt:
            return Color(red: 0.78, green: 0.48, blue: 0.18)
        case .left:
            return Color(red: 0.21, green: 0.56, blue: 0.46)
        case .right:
            return Color(red: 0.46, green: 0.34, blue: 0.72)
        case .upLeft:
            return Color(red: 0.55, green: 0.25, blue: 0.39)
        case .upRight:
            return Color(red: 0.29, green: 0.48, blue: 0.26)
        case .up:
            return Color(red: 0.29, green: 0.34, blue: 0.40)
        case .downLeft:
            return Color(red: 0.40, green: 0.34, blue: 0.24)
        case .downRight:
            return Color(red: 0.35, green: 0.37, blue: 0.24)
        case .down:
            return Color(red: 0.43, green: 0.38, blue: 0.25)
        case .pet:
            return Color(red: 0.80, green: 0.32, blue: 0.40)
        case .bark:
            return Color(red: 0.84, green: 0.62, blue: 0.12)
        }
    }
}

#Preview {
    ContentView(model: MilesMouseModel(currentFrame: MilesFrame(pose: .forward)))
}
