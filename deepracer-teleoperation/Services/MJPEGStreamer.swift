//
//  MJPEGStreamer.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//
import SwiftUI
import Observation


import SwiftUI
import Observation

@Observable
class MJPEGStreamer: NSObject, URLSessionDataDelegate {
    var uiImage: UIImage? = nil
    private var receivedData = Data()
    private var isRunning = false
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        let ip = DeepRacerManager.shared.ipAddress
        let urlString = "https://\(ip)/route?topic=/display_mjpeg&width=480&height=360"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.addValue("https://\(ip)/home", forHTTPHeaderField: "Referer")
        
        // Use the Manager's session but set THIS class as the delegate for data
        let session = URLSession(
            configuration: DeepRacerManager.shared.session.configuration,
            delegate: self,
            delegateQueue: .main
        )
        
        session.dataTask(with: request).resume()
        print("📺 Stream started with boundary: boundarydonotcross")
    }
    
    func stop() {
        isRunning = false
        uiImage = nil
    }

    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard isRunning else { return }
        
        receivedData.append(data)
        
        while true {
            // 1. Find the start marker in the whole buffer
            guard let startRange = receivedData.range(of: Data([0xFF, 0xD8])) else { break }
            
            // 2. Create a "Lookahead" slice starting from the end of the start marker
            let lookahead = receivedData.suffix(from: startRange.upperBound)
            
            // 3. Search for the end marker IN THE SLICE
            // This avoids the 'range' argument error because we search the slice's full extent
            guard let endRange = lookahead.range(of: Data([0xFF, 0xD9])) else { break }
            
            // 4. Extract the frame from the original buffer using the indices from the slice
            let frameData = receivedData.subdata(in: startRange.lowerBound..<endRange.upperBound)
            
            if let image = UIImage(data: frameData) {
                print("update image")
                DispatchQueue.main.async {
                    self.uiImage = image
                }
            }
            
            // 5. Clear everything up to the end of this frame
            receivedData.removeSubrange(0..<endRange.upperBound)
        }
        if receivedData.count > 5_000_000 { receivedData.removeAll() }
        
        print("Probbaly lost video feed")
    }
    
    // Handle SSL Bypass directly in the streamer for safety
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

