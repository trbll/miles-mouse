//
//  ContentView.swift
//  MilesMouse
//
//  Created by Bell, Tyler R on 4/23/26.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: MilesMouseModel
    let onHideMiles: () -> Void

    var body: some View {
        ZStack {
            PlaceholderMilesFrame(frame: model.currentFrame)
                .onTapGesture {
                    model.triggerBark()
                }
                .gesture(
                    DragGesture(minimumDistance: 6)
                        .onChanged { _ in
                            model.triggerPet()
                        }
                )
                .contextMenu {
                    Button("Hide Miles") {
                        onHideMiles()
                    }

                    Divider()

                    Button("Quit MilesMouse") {
                        NSApplication.shared.terminate(nil)
                    }
                }
        }
        .frame(width: 168, height: 188)
        .background(.clear)
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
        case .pet:
            return Color(red: 0.80, green: 0.32, blue: 0.40)
        case .bark:
            return Color(red: 0.84, green: 0.62, blue: 0.12)
        }
    }
}

#Preview {
    ContentView(model: MilesMouseModel(currentFrame: MilesFrame(pose: .forward))) {}
}
