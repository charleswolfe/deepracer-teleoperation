//
//  VideoFeed.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//
import SwiftUI

// MARK: - Video Feed View
//struct VideoFeedView: View {
//
//    @State private var manager = DeepRacerManager.shared
//
//    
//    var body: some View {
//        Rectangle()
//            .fill(
//                LinearGradient(
//                    colors: [.black, .gray.opacity(0.5)],
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//            )
//            .overlay {
//                VStack {
//                    Image(systemName: "video.fill")
//                        .font(.system(size: 60))
//                        .foregroundColor(.white.opacity(0.3))
//                    Text("Video Feed: \(manager.ipAddress)")
//                        .foregroundColor(.white.opacity(0.5))
//                        .font(.caption)
//                }
//            }
//    }
//}

struct VideoFeedView: View {
    @State private var streamer = MJPEGStreamer()
    
    var body: some View {
        ZStack {
            if let image = streamer.uiImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.black
                    VStack {
                        ProgressView()
                            .tint(.white)
                        Text("Waiting for Video...")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
            }
        }
        .onAppear {
            streamer.start()
        }
        .onDisappear {
            streamer.stop() // Critical: Stops the stream when user leaves
        }
    }
}
