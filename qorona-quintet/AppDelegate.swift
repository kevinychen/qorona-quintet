//
//  AppDelegate.swift
//  qorona-quintet
//
//  Created by Kevin Chen on 5/31/20.
//  Copyright © 2020 Kevin Chen. All rights reserved.
//

import Cocoa
import os.log

let SERVER = "http://localhost:8080"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    var musescoreUrl: String!
    var client: String!
    var isMaster: Bool!
    var recorder: Recorder!
    var recordingId: String!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
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
        self.recorder = Recorder()
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
            print("Got consensus at \(timestampEpochMillis)")
            // TODO wait until timestampEpochMillis
            self.run()
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
