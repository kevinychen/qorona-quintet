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
import QuartzCore

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            try run()
        } catch {
            print(error)
        }
    }
    
    func run() throws {
        try runScript(source: """
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
            .replacingOccurrences(of: "{{url}}", with: "https://musescore.com/user/31796599/scores/5560182")
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
        let recorder = try AVAudioRecorder(url: url as URL, format: format)
        recorder.delegate = self
        recorder.prepareToRecord()

        // sync time
        
        print(CACurrentMediaTime())
        let firstSuccess = recorder.record()
        if firstSuccess == false || recorder.isRecording == false {
            recorder.record()
        }
        print(CACurrentMediaTime())
        
        let countdown = 4
        let delay = 1000 // milliseconds
        try runScript(source: """
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
        
        NSWorkspace.shared.openFile(url.path)

        NSApplication.shared.terminate(self)
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
