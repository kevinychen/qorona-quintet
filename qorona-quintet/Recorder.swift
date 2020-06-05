//
//  Recorder.swift
//  qorona-quintet
//
//  Created by Kevin Chen on 6/4/20.
//  Copyright © 2020 Kevin Chen. All rights reserved.
//

import AVFoundation

/**
 * https://stackoverflow.com/questions/8101667/mac-os-x-simple-voice-recorder
 */
class Recorder: NSObject, AVAudioRecorderDelegate {
    
    private var recordingUrl: URL
    private var recorder: AVAudioRecorder
    
    override init() {
        self.recordingUrl = NSURL.fileURL(withPathComponents: [NSTemporaryDirectory(), "recording.m4a"])!
        self.recorder = try! AVAudioRecorder(url: recordingUrl, format: AVAudioFormat(settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderAudioQualityKey: AVAudioQuality.high,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            ])!)
        super.init()
        
        requestMicrophone()
        recorder.delegate = self
        recorder.prepareToRecord()
    }
    
    func record() {
        let firstSuccess = recorder.record()
        if firstSuccess == false || recorder.isRecording == false {
            recorder.record()
        }
    }
    
    func stop() {
        recorder.stop()
    }
    
    func url() -> URL {
        return recordingUrl
    }
}
