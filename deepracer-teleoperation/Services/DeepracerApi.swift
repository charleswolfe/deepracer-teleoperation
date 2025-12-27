//
//  DeepracerApi.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//

import Foundation
import Observation

@Observable
class DeepRacerManager {
    static let shared = DeepRacerManager()
    
    // --- Connection State ---
    var ipAddress: String = "192.168.x.x" // Update with your IP
    var password: String = "your_password"
    var isAuthenticated: Bool = false
    var isLoggingIn: Bool = false
    var lastError: String? = nil  // Added this property
    private var csrfToken: String? = nil  // Store CSRF token for drive commands

    // --- Data State ---
    var batteryLevel: Int = 0
    var isDriving: Bool = false
    var currentAngle: Double = 0
    var currentThrottle: Double = 0
    private var driveTask: Task<Void, Never>?
    
    var videoStreamURL: URL? {
        // DeepRacer uses HTTPS for the camera stream by default
        //https://192.168.7.196/route?topic=/display_mjpeg&width=480&height=360
        let urlString = "https://\(ipAddress)/route?topic=/display_mjpeg&width=480&height=360"
        return URL(string: urlString)
    }
    
    // --- Shared Networking ---
    var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = .shared
        config.httpShouldSetCookies = true
        return URLSession(configuration: config, delegate: SSLBypassDelegate(), delegateQueue: nil)
    }()


    
        
    func login() async {
        // Reset state at start of attempt
        await MainActor.run {
            isLoggingIn = true
            lastError = nil
        }
        
        do {
            let token = try await fetchCSRFToken()
            self.csrfToken = token
            try await performLoginPost(token: token)
            
            await MainActor.run {
                self.isAuthenticated = true
                self.isLoggingIn = false
            }
        } catch {
            // Capture the error message to display in your DeviceLoadingView
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isAuthenticated = false
                self.isLoggingIn = false
            }
        }
    }

    private func fetchCSRFToken() async throws -> String {
        guard let url = URL(string: "https://\(ipAddress)/login") else { throw URLError(.badURL) }
        let (data, _) = try await session.data(for: URLRequest(url: url))
        
        guard let html = String(data: data, encoding: .utf8),
              let token = extractCSRFToken(from: html) else {
            throw NSError(domain: "DeepRacer", code: -1, userInfo: [NSLocalizedDescriptionKey: "CSRF Extraction Failed"])
        }
        return token
    }

    private func performLoginPost(token: String) async throws {
        guard let url = URL(string: "https://\(ipAddress)/login") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+=&"))
        let encodedPw = password.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let encodedToken = token.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        
        let bodyString = "password=\(encodedPw)&csrf_token=\(encodedToken)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func setManualMode() async throws {
        guard let url = URL(string: "https://\(ipAddress)/api/drive_mode") else { return }
        guard let token = csrfToken else {
            throw NSError(domain: "DeepRacer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No CSRF token"])
        }
        
        let body: [String: String] = ["drive_mode": "manual"]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://\(ipAddress)/home", forHTTPHeaderField: "Referer")
        request.setValue(token, forHTTPHeaderField: "X-CSRFToken")
        request.httpBody = jsonData
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    func drive(angle: Double, throttle: Double) async throws {
        guard let url = URL(string: "https://\(ipAddress)/api/manual_drive") else { return }
        guard let token = csrfToken else {
            print("❌ No CSRF token available")
            throw NSError(domain: "DeepRacer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No CSRF token"])
        }
        
        // DeepRacer expects numeric values, not strings
        let body: [String: Any] = [
            "angle": angle,
            "throttle": throttle,
            "max_speed": 0.5
        ]
        
        print("🚗 Sending drive command: angle=\(angle), throttle=\(throttle)")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("❌ Failed to serialize JSON")
            return
        }
        
        // Debug: print the actual JSON being sent
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("   JSON: \(jsonString)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://\(ipAddress)/home", forHTTPHeaderField: "Referer")
        request.setValue(token, forHTTPHeaderField: "X-CSRFToken")  // Add CSRF token header
        request.httpBody = jsonData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            print("❌ Drive failed with status: \(httpResponse.statusCode)")
            if let responseStr = String(data: data, encoding: .utf8) {
                print("   Response: \(responseStr)")
            }
            throw URLError(.badServerResponse)
        }
    }
    
    func startdrive() async throws {
        guard let url = URL(string: "https://\(ipAddress)/api/start_stop") else { return }
        guard let token = csrfToken else {
            throw NSError(domain: "DeepRacer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No CSRF token"])
        }
        
        let body: [String: String] = ["start_stop": "start"]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://\(ipAddress)/home", forHTTPHeaderField: "Referer")
        request.setValue(token, forHTTPHeaderField: "X-CSRFToken")
        request.httpBody = jsonData
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    func stopdrive() async throws {
        guard let url = URL(string: "https://\(ipAddress)/api/start_stop") else { return }
        guard let token = csrfToken else {
            throw NSError(domain: "DeepRacer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No CSRF token"])
        }
        
        let body: [String: String] = ["start_stop": "stop"]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://\(ipAddress)/home", forHTTPHeaderField: "Referer")
        request.setValue(token, forHTTPHeaderField: "X-CSRFToken")
        request.httpBody = jsonData
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    func fetchBatteryLevel() async {
        // If we aren't logged in, don't even try
        guard isAuthenticated else { return }
        
        guard let url = URL(string: "https://\(ipAddress)/api/get_battery_level") else { return }
        
        do {
            let (data, _) = try await session.data(for: URLRequest(url: url))
            
            
            // 2. Print Raw Data to see the "HTML"
                    if let rawString = String(data: data, encoding: .utf8) {
                        if rawString.contains("<!DOCTYPE html>") || rawString.contains("<html") {
                            print("DEBUG: Received HTML instead of JSON. You have likely been logged out.")
                            // If we get HTML, we are no longer authenticated
                            await MainActor.run { self.isAuthenticated = false }
                            return
                        }
                        print("Raw Response: \(rawString)")
                    }
            
            let result = try JSONDecoder().decode(BatteryResponse.self, from: data)
            
            await MainActor.run {
                self.batteryLevel = result.batteryLevel
            }
        } catch {
            print("Battery Fetch Error: \(error)")
        }
    }

    // MARK: - CSRF Helper (Your Regex Logic)
    func extractCSRFToken(from html: String) -> String? {
        // Try to find CSRF token in meta tag: <meta name="csrf-token" content="TOKEN">
        if let metaRange = html.range(of: "<meta name=\"csrf-token\" content=\"([^\"]+)\"", options: .regularExpression) {
            let metaTag = String(html[metaRange])
            if let contentRange = metaTag.range(of: "content=\"([^\"]+)\"", options: .regularExpression) {
                let content = String(metaTag[contentRange])
                return content.replacingOccurrences(of: "content=\"", with: "").replacingOccurrences(of: "\"", with: "")
            }
        }

        // Try to find CSRF token in hidden input: <input type="hidden" name="csrf_token" value="TOKEN">
        if let inputRange = html.range(of: "<input[^>]*name=\"csrf_token\"[^>]*value=\"([^\"]+)\"", options: .regularExpression) {
            let inputTag = String(html[inputRange])
            if let valueRange = inputTag.range(of: "value=\"([^\"]+)\"", options: .regularExpression) {
                let value = String(inputTag[valueRange])
                return value.replacingOccurrences(of: "value=\"", with: "").replacingOccurrences(of: "\"", with: "")
            }
        }

        return nil
    }
    
    
    
    func updateSteering(angle: Double) {
            currentAngle = angle
            ensureDriveSession()
        }
        
        /// Update throttle from ThrottleControl
        func updateThrottle(throttle: Double) {
            currentThrottle = throttle
            ensureDriveSession()
        }
        
        /// Ensures drive session is started and sends drive commands
        private func ensureDriveSession() {
            // Check if both controls are at zero
            if currentAngle == 0 && currentThrottle == 0 {
                stopDriveSession()
                return
            }
            
            // Start drive session if not already driving
            if !isDriving {
                startDriveSession()
            } else {
                // Send updated drive command
                sendDriveCommand()
            }
        }
        
        /// Starts the drive session
        private func startDriveSession() {
            guard !isDriving else { return }
            
            isDriving = true
            
            // Start the drive session on the device
            Task {
                do {
                    // 1. First set manual mode
                    try await setManualMode()
                    print("✓ Manual mode set")
                    
                    // 2. Then start the drive session
                    try await startdrive()
                    print("✓ Drive session started")
                    
                    // 3. Small delay to let the device settle
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    
                    // 4. Begin continuous drive command loop
                    startDriveLoop()
                } catch {
                    print("Failed to start drive session: \(error)")
                    if let urlError = error as? URLError {
                        print("  URL Error code: \(urlError.code.rawValue)")
                    }
                    await MainActor.run {
                        isDriving = false
                    }
                }
            }
        }
        
        /// Stops the drive session
        private func stopDriveSession() {
            guard isDriving else { return }
            
            // Cancel the continuous drive loop
            driveTask?.cancel()
            driveTask = nil
            
            isDriving = false
            
            // Stop the drive session on the device
            Task {
                do {
                    try await stopdrive()
                } catch {
                    print("Failed to stop drive session: \(error)")
                }
            }
        }
        
        /// Continuously sends drive commands while driving
        private func startDriveLoop() {
            driveTask?.cancel()
            
            driveTask = Task {
                while !Task.isCancelled && isDriving {
                    sendDriveCommand()
                    
                    // Send updates at ~20Hz (50ms intervals)
                    try? await Task.sleep(nanoseconds: 50_000_000)
                }
            }
        }
        
        /// Sends a single drive command with current angle and throttle
        private func sendDriveCommand() {
            Task {
                do {
                    try await drive(angle: currentAngle, throttle: currentThrottle)
                } catch {
                    print("Drive command failed: \(error)")
                }
            }
        }
    
    
}


class SSLBypassDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Bypass SSL certificate validation
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }
        completionHandler(.performDefaultHandling, nil)
    }
}
