//
//  Applescripts.swift
//  qorona-quintet
//
//  Created by Kevin Chen on 6/4/20.
//  Copyright © 2020 Kevin Chen. All rights reserved.
//

func openChromeMusescoreInFullscreen(musescoreUrl: String) {
    try! runApplescript(source: """
tell application "Google Chrome"
    activate

    tell window 1
        # open URL
        set newTab to make new tab with properties {URL:"{{musescoreUrl}}"}

        delay 3
    end tell

    tell newTab
        # play
        execute javascript "document.querySelectorAll('._13vRI._1ci-r._3qfU_._3ysVT._1Us9e.Hj1bK._8B-BO._15kzJ')[1].click()"
    end tell

    delay 3

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
end tell
"""
        .replacingOccurrences(of: "{{musescoreUrl}}", with: musescoreUrl)
    )
}

func toggleZoomRecord() {
    try! runApplescript(source: """
# start record on Zoom
tell application "zoom.us" to activate
tell application "System Events"
    keystroke "r" using { shift down, command down }
end tell
"""
    )
}

func doChromeCountdownAndPlay(countdown: Int, delayMillis: Int) {
    try! runApplescript(source: """
# show countdown timer
tell application "Google Chrome"
    tell active tab of window 1
        execute javascript "document.querySelector('._15eP_').insertAdjacentHTML('beforeend', \\"<style>#qorona-quintet { position: fixed; top: 40%; width: 100vw; pointer-events: none; font-size: 200px; text-align: center; }</style> <div id='qorona-quintet'></div>\\"); let qorona_quintet_countdown = {{countdown}}; let qorona_quintet_interval = window.setInterval(function() { qorona_quintet_countdown--; if (qorona_quintet_countdown === 0) { window.clearInterval(qorona_quintet_interval); } document.getElementById('qorona-quintet').textContent = qorona_quintet_countdown || ''; }, {{delayMillis}});"
    end tell
end tell

delay {{totalDelaySec}}

# play
tell application "Google Chrome"
    tell active tab of window 1
        execute javascript "document.querySelectorAll('._13vRI._1ci-r._3qfU_._3ysVT._1Us9e.Hj1bK._8B-BO._15kzJ')[1].click()"
    end tell
end tell
"""
        .replacingOccurrences(of: "{{countdown}}", with: String(countdown))
        .replacingOccurrences(of: "{{delayMillis}}", with: String(delayMillis))
        .replacingOccurrences(of: "{{totalDelaySec}}", with: String(countdown * delayMillis / 1000))
    )
}

func exitChromeFullscreen() {
    try! runApplescript(source: """
tell application "Google Chrome"
    activate

    # if still playing, click stop
    tell active tab of window 1
        execute javascript "if (document.querySelectorAll('._13vRI._1ci-r._3qfU_._3ysVT._1Us9e.Hj1bK._8B-BO._15kzJ')[1].getElementsByTagName('path').length === 2) { document.querySelectorAll('._13vRI._1ci-r._3qfU_._3ysVT._1Us9e.Hj1bK._8B-BO._15kzJ')[1].click(); }"
    end tell
end tell

# click escape to exit fullscreen
tell application "System Events" to key code 53
"""
    )
}
