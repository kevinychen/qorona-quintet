//
//  Utils.swift
//  qorona-quintet
//
//  Created by Kevin Chen on 5/31/20.
//  Copyright © 2020 Kevin Chen. All rights reserved.
//

import AVFoundation
import os.log

func runApplescript(source: String) throws {
    let script = NSAppleScript(source: source)!
    var error: NSDictionary? = nil
    script.executeAndReturnError(&error)
    if (error != nil) {
        os_log("%@", error!)
        throw NSError()
    }
}

func postUrl(url: String, callback: @escaping (Any?) -> ()) {
    var request = URLRequest(url: URL(string: url)!)
    request.httpMethod = "POST"
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if data!.isEmpty {
            callback(nil)
            return
        }
        let json = try! JSONSerialization.jsonObject(with: data!, options: [])
        callback(json)
    }
    task.resume()
}

func requestMicrophone() {
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
}

func uploadFile(url: String, fileUrl: URL, contentType: String, callback: @escaping () -> Void) {
    var request: URLRequest = URLRequest(url: URL(string: url)!)
    request.httpMethod = "POST"
    
    let boundary = "Boundary-\(NSUUID().uuidString)"
    request.setValue("multipart/form-data; boundary=" + boundary, forHTTPHeaderField: "Content-Type")
    
    let data = try! Data(contentsOf: fileUrl)
    let fullData = toFormData(data: data, boundary: boundary, fileName: "name", contentType: contentType)
    request.setValue(String(fullData.count), forHTTPHeaderField: "Content-Length")
    
    request.httpBody = fullData
    request.httpShouldHandleCookies = false
    
    let session = URLSession(configuration: .default)
    let task = session.dataTask(with: request) { (data, response, error) in
        callback()
    }
    task.resume()
}

private func toFormData(data: Data, boundary: String, fileName: String, contentType: String) -> Data {
    var fullData = Data()
    
    let lineOne = "--" + boundary + "\r\n"
    fullData.append(lineOne.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
    
    let lineTwo = "Content-Disposition: form-data; name=\"file\"; filename=\"" + fileName + "\"\r\n"
    fullData.append(lineTwo.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
    
    let lineThree = "Content-Type: \(contentType)\r\n\r\n"
    fullData.append(lineThree.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
    
    fullData.append(data)
    
    let lineFive = "\r\n"
    fullData.append(lineFive.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
    
    let lineSix = "--" + boundary + "--\r\n"
    fullData.append(lineSix.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
    
    return fullData
}
