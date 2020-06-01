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
        let helloScript = """
tell me
    activate
    display dialog "Hello!"
end tell
"""

        let script = NSAppleScript(source: helloScript)!
        var error: NSDictionary? = nil
        script.executeAndReturnError(&error)
        if (error != nil) {
            os_log("%@", error!)
        }
        
        NSApplication.shared.terminate(self)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
