//
//  VideoFeed.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//
import SwiftUI

struct VideoFeedView: View {
    @State private var streamer = MJPEGStreamer()
    
    var body: some View {
        ZStack {
            if let image = streamer.uiImage {
//                Image(uiImage: image)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
                
                GeometryReader { geo in
                    let isLandscape = geo.size.width > geo.size.height
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: isLandscape ? .fill : .fit)
                        // 1. Explicitly set the frame to the geo size
                        // 2. Center the content within that frame
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                        // 3. Clip AFTER the frame is set so it doesn't bleed over other UI
                        //.clipped()
                }
                .ignoresSafeArea()
                
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
