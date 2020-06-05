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
    end tell
end tell

tell application "System Events"
    # fullscreen
    keystroke "f" using { command down, control down }
end tell

tell application "Google Chrome"
    # fullscreen formatting
    tell newTab
        execute javascript "document.querySelectorAll('._13vRI._1ci-r._3qfU_._3ysVT._1Us9e.Hj1bK._8B-BO._15kzJ')[8].click()"
    end tell

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
        sleep(2)
        print(CACurrentMediaTime())
        try runScript(source: """
tell application "Google Chrome"
    tell active tab of window 1
        execute javascript "document.querySelectorAll('._13vRI._1ci-r._3qfU_._3ysVT._1Us9e.Hj1bK._8B-BO._15kzJ')[1].click()"
    end tell
end tell
"""
        )
        print(CACurrentMediaTime())
        
        sleep(5)
        recorder.stop()

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
