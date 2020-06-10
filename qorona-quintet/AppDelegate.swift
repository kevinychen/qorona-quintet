//
//  AppDelegate.swift
//  qorona-quintet
//
//  Created by Kevin Chen on 5/31/20.
//  Copyright © 2020 Kevin Chen. All rights reserved.
//

import Cocoa
import os.log
import TrueTime

let SERVER = Bundle.main.infoDictionary?["SERVER"] as! String

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    var clientId: UUID!
    var ntpClient: TrueTimeClient!
    var recorder: Recorder!
    var isMaster: Bool!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        clientId = UUID()
        ntpClient = TrueTimeClient.sharedInstance
        ntpClient.start()
        recorder = Recorder()
        
        httpCall(url: "\(SERVER)/api/config", method: "GET") { json in
            let config = json as! [String: Any]
            let musescoreUrl = config["musescoreUrl"] as! String
            openChromeMusescoreInFullscreen(musescoreUrl: musescoreUrl)
            self.waitForConsensus()
        }
    }
    
    func waitForConsensus() {
        httpCall(url: "\(SERVER)/api/consensus/\(clientId!)", method: "POST") { json in
            let consensus = json as! [String: Any]
            self.isMaster = consensus["master"] as? Bool
            let startTimeEpochMillis = consensus["startTimeEpochMillis"] as! Int64
            if startTimeEpochMillis == -1 {
                print("No consensus. Polling again after 1 second.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.waitForConsensus()
                }
                return
            }
            let currentEpochMillis = Int64(((self.ntpClient.referenceTime?.now().timeIntervalSince1970)! * 1000.0).rounded())
            let waitMillis = Int(startTimeEpochMillis - currentEpochMillis)
            print("Current time: \(currentEpochMillis). Start time: \(startTimeEpochMillis). Wait time: \(waitMillis)")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(waitMillis)) {
                self.run()
            }
        }
    }
    
    func run() {
        print("Starting Zoom recording at \(CACurrentMediaTime())")
        toggleZoomRecordIfMaster()
        
        print("Starting audio recording at \(CACurrentMediaTime())")
        recorder.record()

        print("Starting countdown at \(CACurrentMediaTime())")
        doChromeCountdownAndPlay(countdown: 11, delayMillis: 1000)
        print("Started MuseScore at \(CACurrentMediaTime())")
        
        waitForDone()
    }
    
    func waitForDone() {
        httpCall(url: "\(SERVER)/api/config/", method: "GET") { json in
            let config = json as! [String: Any]
            let isDone = config["done"] as! Bool
            if !isDone {
                print("Not done yet. Polling again after 1 second.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.waitForDone()
                }
                return
            }
            print("Done! Finishing and uploading recording.")
            self.done()
        }
    }
    
    func done() {
        recorder.stop()
        toggleZoomRecordIfMaster()
        exitChromeFullscreen()
        uploadFile(url: "\(SERVER)/api/upload/audio/\(clientId!)", fileUrl: recorder.url(), contentType: "audio/mp4") { () in
            NSApplication.shared.terminate(self)
        }
    }

    private func toggleZoomRecordIfMaster() {
        if (isMaster) {
            toggleZoomRecord()
        } else {
            usleep(100000) // dummy delay that takes roughly the same amount of time; 100,000us = 100ms
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}
