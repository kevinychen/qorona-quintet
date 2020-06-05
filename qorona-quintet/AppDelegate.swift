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

let SERVER = "http://localhost:8080"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    var ntpClient: TrueTimeClient!
    var musescoreUrl: String!
    var client: String!
    var isMaster: Bool!
    var recorder: Recorder!
    var recordingId: String!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        ntpClient = TrueTimeClient.sharedInstance
        ntpClient.start()
        
        postUrl(url: SERVER + "/api/ready") { json in
            let readyResponse = json as! [String: Any]
            self.musescoreUrl = readyResponse["musescoreUrl"] as? String
            self.client = readyResponse["client"] as? String
            self.isMaster = readyResponse["master"] as? Bool
            self.prepare()
        }
    }
    
    func prepare() {
        openChromeMusescoreInFullscreen(musescoreUrl: musescoreUrl)
        recorder = Recorder()
        waitForConsensus()
    }
    
    func waitForConsensus() {
        postUrl(url: SERVER + "/api/ping/\(client!)") { json in
            if (json == nil) {
                print("No consensus. Polling again after 1 second.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.waitForConsensus()
                }
                return
            }
            let consensus = json as! [String: Any]
            self.recordingId = consensus["recordingId"] as? String
            
            let timestampEpochMillis = consensus["timestampEpochMillis"] as! Int64
            let currentEpochMillis = Int64(((self.ntpClient.referenceTime?.now().timeIntervalSince1970)! * 1000.0).rounded())
            let waitMillis = Int(timestampEpochMillis - currentEpochMillis)
            print("Current time: \(currentEpochMillis). Consensus time: \(timestampEpochMillis). Wait time: \(waitMillis)")
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
        doChromeCountdownAndPlay(countdown: 4, delayMillis: 1000)
        print("Started MuseScore at \(CACurrentMediaTime())")
        
        waitForDone()
    }
    
    func waitForDone() {
        postUrl(url: SERVER + "/api/ping/") { json in
            let doneResponse = json as! [String: Bool]
            let done = doneResponse["done"]!
            if !done {
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
        uploadFile(url: SERVER + "/api/upload/audio/\(recordingId!)/\(client!)", fileUrl: recorder.url(), contentType: "audio/mp4") { () in
            NSApplication.shared.terminate(self)
        }
    }

    private func toggleZoomRecordIfMaster() {
        if (isMaster) {
            toggleZoomRecord()
        } else {
            sleep(100) // dummy delay that takes roughly the same amount of time
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}
