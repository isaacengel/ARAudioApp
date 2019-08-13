//
//  OSCManager.swift
//  PlaybackAndEQ_v2
//
//  Created by Mark Steadman on 12/05/2017.
//  Copyright © 2017 Isaac. All rights reserved.
//

import Foundation

class OSCManager : OSCServerDelegate {
    
    // Singleton shared instance
    static let sharedInstance = OSCManager()
    
    // AudioKit session singleton
    let session = AudioKitSession.sharedInstance
    
    let VR = 1
    let AR = 2
    var client = OSCClient(address: "localhost", port: 8080)
    var server = OSCServer(address: "", port: 8081) // 3rd july
    var currentMode = 1 // VR
    var countdownEnabled = false // when true, AR mode switches back to VR after 'countdownTime' seconds
    let countdownTime : TimeInterval = 10 // seconds to switch AR to VR
    
    var previousAmplitude = 0.0
    let volumeThreshold = 0.05
    
    var timer : Timer!
    
    public func initialize() {
        
    }
    
    public func start() {
        startServer()
        previousAmplitude = session.getMicAmplitude()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(OSCManager.OSCcallback), userInfo: nil, repeats: true)
        print("OSC: Started OSC manager") // debug
    }
    
    public func stop() {
        timer.invalidate()
        print("OSC: Stopped OSC manager") // debug
    }
    
    @objc func OSCcallback() {
        let a = session.getMicAmplitude()
        let da = a - previousAmplitude
        previousAmplitude = a
        
        if (da > volumeThreshold && currentMode == VR) {
            sendOSCMessage(mode: AR)
            changeMode(mode: AR)
            print("OSC: Reached threshold. Initiating AR mode...") // debug
            if(countdownEnabled) {
                startCountdown()
                print("OSC: Starting countdown...") // debug
            }
        }
    }
    
    func startCountdown() {
        _ = Timer.scheduledTimer(timeInterval: countdownTime, target: self, selector: #selector(countdownEnded), userInfo: nil, repeats: false)
    }
    
    @objc func countdownEnded() {
        sendOSCMessage(mode: VR)
        changeMode(mode: VR)
        print("OSC: End of countdown. Initiating VR mode...") // debug
    }
    
    func sendOSCMessage(mode: Int) {
        let message = OSCMessage(
            OSCAddressPattern("/"),
            mode
        )
        client.send(message)
        print("OSC: Sending OSC message: mode = ", mode) // debug
    }
    
    func startServer() { // 3rd july
        server.start()
        server.delegate = self
        print("OSC: Server started") // debug
    }
    
    func didReceive(_ message: OSCMessage) { // 3rd july
        if message.arguments.count > 0 {
            if let mode = message.arguments[0] as? Int {
                print("OSC: Received mode =", mode) // debug
                if mode == VR || mode == AR {
                    changeMode(mode: mode)
                } else {
                    print("OSC: Received invalid mode") // debug
                }
            } else {
                print("OSC: Error: message was not an integer") // debug
            }
        } else {
            print("OSC: Error: message was empty") // debug
        }
    }
    
    func changeMode(mode: Int) { // 3rd july
        if mode == VR {
            print("OSC: Changing to VR mode...") // debug
            currentMode = VR
            session.mixer.volume = 0.1
        } else if mode == AR {
            print("OSC: Changing to AR mode...") // debug
            currentMode = AR
            session.mixer.volume = 1.0
        } else {
            print("OSC: Received invalid mode") // debug
        }
    }
    
    func enableCountdown(enable: Bool) {
        countdownEnabled = enable
        enable ? print("OSC: countdown enabled") : print("OSC: countdown disabled") // debug
    }
    
}
