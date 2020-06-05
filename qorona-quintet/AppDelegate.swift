//
//  AppDelegate.swift
//  qorona-quintet
//
//  Created by Kevin Chen on 5/31/20.
//  Copyright © 2020 Kevin Chen. All rights reserved.
//

import AVFoundation
import Cocoa
import os.log

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    let SERVER = "http://localhost:8080"
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        run()
    }
    
    func run() {
        postUrl(url: SERVER + "/api/ready") { json in
            let readyResponse = json as! [String: Any]
            let musescoreUrl = readyResponse["musescoreUrl"] as! String
            let client = readyResponse["client"] as! String
            let isHost = readyResponse["host"] as! Bool
            self.runWithConfig(musescoreUrl: musescoreUrl, client: client, isHost: isHost)
        }
    }
    
    func runWithConfig(musescoreUrl: String, client: String, isHost: Bool) {
        try! runScript(source: """
display dialog "In Google Chrome, go to View -> Developer and ensure 'Allow JavaScript from Apple Events' is checked."

tell application "Google Chrome"
    activate
    tell window 1
        set newTab to make new tab with properties {URL:"{{url}}"}
    end tell
end tell

tell me
    activate
    display dialog "Clicking play and then stop to force-download the music..." giving up after 2
end tell

tell application "Google Chrome"
    activate

    tell newTab
        # play
        execute javascript "document.querySelectorAll('._13vRI._1ci-r._3qfU_._3ysVT._1Us9e.Hj1bK._8B-BO._15kzJ')[1].click()"
    end tell

    delay 2

    tell newTab
        # pause
        execute javascript "document.querySelectorAll('._13vRI._1ci-r._3qfU_._3ysVT._1Us9e.Hj1bK._8B-BO._15kzJ')[1].click()"
        # rewind
        execute javascript "document.querySelectorAll('._13vRI._1ci-r._3qfU_._3ysVT._1Us9e.Hj1bK._8B-BO._15kzJ')[0].click()"
        # add keyboard listener for fullscreen
        execute javascript "document.onkeypress = e => { if (e.key === '~') document.querySelector('._15eP_').requestFullscreen() }"
    end tell

    delay 1
end tell

# invoke fullscreen
tell application "System Events"
    keystroke "~"

    delay 2
end tell
"""
            .replacingOccurrences(of: "{{url}}", with: musescoreUrl)
        )

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: // The user has previously granted access to the camera.
            ()
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    // proceed with recording
                }
            }
        case .denied: // The user has previously denied access.
            ()
        case .restricted: // The user can't grant access due to restrictions.
            ()
        @unknown default:
            fatalError()
        }
        let url = NSURL.fileURL(withPathComponents: [NSTemporaryDirectory(), "recording.m4a"])!
        print(url)
        let format = AVAudioFormat(settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderAudioQualityKey: AVAudioQuality.high,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            ])!
        let recorder = try! AVAudioRecorder(url: url as URL, format: format)
        recorder.delegate = self
        recorder.prepareToRecord()

        // sync time
        
        print(CACurrentMediaTime())
        toggleZoomRecord(isHost: isHost)
        print(CACurrentMediaTime())
        let firstSuccess = recorder.record()
        if firstSuccess == false || recorder.isRecording == false {
            recorder.record()
        }
        print(CACurrentMediaTime())
        
        let countdown = 4
        let delay = 1000 // milliseconds
        try! runScript(source: """
# show countdown timer
tell application "Google Chrome"
    tell active tab of window 1
        execute javascript "document.querySelector('._15eP_').insertAdjacentHTML('beforeend', \\"<style>#qorona-quintet { position: fixed; top: 40%; width: 100vw; pointer-events: none; font-size: 200px; text-align: center; }</style> <div id='qorona-quintet'></div>\\"); let qorona_quintet_countdown = {{countdown}}; let qorona_quintet_interval = window.setInterval(function() { qorona_quintet_countdown--; if (qorona_quintet_countdown === 0) { window.clearInterval(qorona_quintet_interval); } document.getElementById('qorona-quintet').textContent = qorona_quintet_countdown || ''; }, {{delay}});"
    end tell
end tell

delay {{total_delay}}

# play
tell application "Google Chrome"
    tell active tab of window 1
        execute javascript "document.querySelectorAll('._13vRI._1ci-r._3qfU_._3ysVT._1Us9e.Hj1bK._8B-BO._15kzJ')[1].click()"
    end tell
end tell
"""
            .replacingOccurrences(of: "{{countdown}}", with: String(countdown))
            .replacingOccurrences(of: "{{delay}}", with: String(delay))
            .replacingOccurrences(of: "{{total_delay}}", with: String(countdown * delay / 1000))
        )
        print(CACurrentMediaTime())
        
        sleep(8)
        recorder.stop()
        toggleZoomRecord(isHost: isHost)
        
        let recordingId = "00000000-0000-0000-0000-00000000000"
        let client = "00000000-0000-0000-0000-00000000000"
        uploadFile(url: SERVER + "/api/upload/audio/\(recordingId)/\(client)", fileUrl: url, contentType: "audio/mp4") { () in
            NSApplication.shared.terminate(self)
        }
    }
    
    func postUrl(url: String, callback: @escaping (Any) -> ()) {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 503 {
                    print("No music configured yet.")
                    return
                }
                let json = try! JSONSerialization.jsonObject(with: data!, options: [])
                callback(json)
            }
        }
        task.resume()
    }
    
    func uploadFile(url: String, fileUrl: URL, contentType: String, callback: @escaping () -> Void) {
        var request: URLRequest = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(NSUUID().uuidString)"
        request.setValue("multipart/form-data; boundary=" + boundary, forHTTPHeaderField: "Content-Type")
        
        let data = try! Data(contentsOf: fileUrl)
        let fullData = toFormData(data: data, boundary: boundary, fileName: "name", contentType: contentType)
        request.setValue(String(fullData.count), forHTTPHeaderField: "Content-Length")
        
        request.httpBody = fullData
        request.httpShouldHandleCookies = false
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { (data, response, error) in
            callback()
        }
        task.resume()
    }
    
    func toFormData(data: Data, boundary: String, fileName: String, contentType: String) -> Data {
        var fullData = Data()
        
        let lineOne = "--" + boundary + "\r\n"
        fullData.append(lineOne.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        
        let lineTwo = "Content-Disposition: form-data; name=\"file\"; filename=\"" + fileName + "\"\r\n"
        fullData.append(lineTwo.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        
        let lineThree = "Content-Type: \(contentType)\r\n\r\n"
        fullData.append(lineThree.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        
        fullData.append(data)
        
        let lineFive = "\r\n"
        fullData.append(lineFive.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        
        let lineSix = "--" + boundary + "--\r\n"
        fullData.append(lineSix.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        
        return fullData
    }
    
    func toggleZoomRecord(isHost: Bool) {
        if (isHost) {
            try! runScript(source: """
# start record on Zoom
tell application "zoom.us" to activate
tell application "System Events"
    keystroke "r" using { shift down, command down }
end tell
"""
            )
        } else {
            sleep(100) // dummy delay that takes roughly the same amount of time
        }
    }

    func runScript(source: String) throws {
        let script = NSAppleScript(source: source)!
        var error: NSDictionary? = nil
        script.executeAndReturnError(&error)
        if (error != nil) {
            os_log("%@", error!)
            throw NSError()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print(flag)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print(error)
    }
}
