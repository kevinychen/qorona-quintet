//
//  AppDelegate.swift
//  qorona-quintet
//
//  Created by Kevin Chen on 5/31/20.
//  Copyright © 2020 Kevin Chen. All rights reserved.
//

import Cocoa
import os.log

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        runScript(source: """
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
        
        // sync time
        
        runScript(source: """
tell application "Google Chrome"
    tell active tab of window 1
        execute javascript "document.querySelectorAll('._13vRI._1ci-r._3qfU_._3ysVT._1Us9e.Hj1bK._8B-BO._15kzJ')[1].click()"
    end tell
end tell
"""
        )

        NSApplication.shared.terminate(self)
    }
    
    func runScript(source: String) {
        let script = NSAppleScript(source: source)!
        var error: NSDictionary? = nil
        script.executeAndReturnError(&error)
        if (error != nil) {
            os_log("%@", error!)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
