Qorona-Quintet Automated Synchronized Recorder (QQASR)
======================================================

QQASR (pronounced "quasar") allows remote users to simultaneously play and record music to a synchronized MuseScore soundtrack, and combines the recordings into a single file.

QQASR consists of a server and multiple client MacOSX applications. Here's what it does:

- The host inputs a MuseScore piece and the number of participants
- The clients use Network Time Protocol (NTP) to ensure their clocks are synchronized with each other
- The master client automatically starts a Zoom video recording
- Each client opens the MuseScore page, and QQASR shows a countdown timer before starting the soundtrack to give everyone a chance to prepare
- Each client records their music separately, but simultaneously
- Once the host signals that the soundtrack is over, all clients finish their recordings and send them to the server
- The server merges the recordings together!

Detailed instructions
---------------------

First time setup:

- All clients should allow JavaScript events from AppleScript in Google Chrome. Under View -> Developer, select "Allow JavaScript from Apple Events".
- All clients should run the application once to (1) grant Microphone access (to record music), (2) grant Accessibility access (open music in Chrome), and (3) grant Automation access (to enable Chrome fullscreen). These will automatically be requested the first time you run the app. If you accidentally clicked "Don't Allow", you can fix it in System Preferences -> Security & Privacy -> Microphone/Accessibility/Automation.

To run:

- Master client goes to `https://server:8100` and inputs the URL of the MuseScore piece and the number of clients (including the master)
- Master client should ensure Zoom is running and in Gallery View.
- Master client should ensure they have record permissions from the Zoom meeting host.
- All clients should ensure Google Chrome is running.
- Master client starts the application first.
- All other clients also start the application.
- After the soundtrack finishes, master client should hit "Done" in the UI.
- Master client leaves the Zoom meeting in order to convert the video recording.
- Master client uploads the video recording in the UI.

Development
-----------

First time setup:

    brew install carthage  # Swift dependency manager
    carthage bootstrap
    cd qorona-quintet-server && ./gradlew eclipse  # Server classpath

To start the server, either run `Server.java` in Eclipse, or:

    cd qorona-quintet-server
    ./gradlew run

The client can be built and run in XCode. Alternatively, export the client application in XCode by clicking Product -> Archive -> Distribute App -> Development.

