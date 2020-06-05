Qorona-Quintet Automated Synchronized Recorder (QQASR)
------------------------------------------------------

QQASR (pronounced "quasar") allows remote users to simultaneously play and record music to a synchronized MuseScore soundtrack, and combines the recordings into a single file.

QQASR consists of a server and multiple client MacOSX applications. Here's what it does:

- The host inputs a MuseScore piece and the number of participants
- The clients use Network Time Protocol (NTP) to ensure their clocks are synchronized with each other
- The master client automatically starts a Zoom video recording
- Each client opens the MuseScore page, and QQASR shows a countdown timer before starting the soundtrack to give everyone a chance to prepare
- Each client records their music separately, but simultaneously
- Once the host signals that the soundtrack is over, all clients finish their recordings and send them to the server
- The server merges the recordings together!

