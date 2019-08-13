//
//  AudioKitSession.swift
//  PlaybackAndEQ_v2
//
//  Created by Mark Steadman on 11/05/2017.
//  Copyright © 2017 Isaac. All rights reserved.
//

import AudioKit

// Custom types
enum Channel {
    case left
    case right
}

enum GainSetting {
    case none
    case mild
    case moderate
    case severe
}

class AudioKitSession {
    
    // Singleton shared instance
    static let sharedInstance = AudioKitSession()
    
    // AudioKit objects
    public var mixer : AKMixer! // public mixer
    let mic = AKMicrophone()
    var EQright = [AKEqualizerFilter] ()
    var EQleft = [AKEqualizerFilter] ()
    var earCanalEQ1 : AKLowShelfParametricEqualizerFilter!
    var earCanalEQ2 : AKEqualizerFilter!
    var earCanalEQ3 : AKEqualizerFilter!
    var tracker: AKAmplitudeTracker! // for the OSC trigger condition
    
    // EQ parameters
    let centerFrequencies: [Double] = [62.5, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    let bandwidths: [Double] = [42, 83, 167, 333, 667, 1333, 2667, 5333, 10667] // just enough to cover the whole spectrum without overlapping
    let gainNone: [Double] = [1, 1, 1, 1, 1, 1, 1, 1, 1] //[0, 0, 0, 0, 0, 0, 0, 0, 0]
    let gainMild: [Double] = [0.4467, 0.4467, 0.2512, 0.1778, 0.0794, 0.0562, 0.0562, 0.0562, 0.0562] //[-7, -7, -12, -15, -22, -25, -25, -25, -25]
    let gainModerate: [Double] = [0.0794, 0.0794, 0.0447, 0.0316, 0.0141, 0.0100, 0.0100, 0.0100, 0.0100] // [-22, -22, -27, -30, -37, -40, -40, -40, -40]
    let gainSevere: [Double] = [0.0045, 0.0045, 0.0025, 0.0018, 0.0008, 0.0006, 0.0006, 0.0006, 0.0006] // [-47, -47, -52, -55, -62, -65, -65, -65, -65]
    
    public func initialize() {
        // Configures AudioKit
        AKSettings.bufferLength = .shortest // this is 0.72 ms
        
        // Sets the chain of audio nodes, from mic to output
        // First, we connect the mic to the main mixer, to which we can later conect the recorder too
        tracker = AKAmplitudeTracker.init(mic) // this is used to track the amplitude of the mic, to trigger OSC messages
        mixer = AKMixer(tracker)
        
        // Then, we add the ear canal compensation, which consists in 3 filters
        earCanalEQ1 = AKLowShelfParametricEqualizerFilter(mixer, cornerFrequency: 700, gain: 0.178, q: 0.7)
        earCanalEQ2 = AKEqualizerFilter(earCanalEQ1, centerFrequency: 1500, bandwidth: 2000, gain: 1.995)
        earCanalEQ3 = AKEqualizerFilter(earCanalEQ2, centerFrequency: 14000, bandwidth: 4000, gain: 5.623)
        
        setEarCanalCompensation(value: false) // We turn the compensation off initially, which later can be enabled using the switch
        
        // Then, we split the signal in left and right channels with the help of two AKBoosters
        let boostLeft = AKBooster(earCanalEQ3)
        let boostRight = AKBooster(earCanalEQ3)
        boostLeft.leftGain = 1
        boostLeft.rightGain = 0
        boostRight.leftGain = 0
        boostRight.rightGain = 1
        
        // Then, we add the band equalizers for both channels, which consist in 9 filters each
        EQleft.append(AKEqualizerFilter(boostLeft))
        for index in 0...7 {
            EQleft.append(AKEqualizerFilter(EQleft[index]))
        }
        
        EQright.append(AKEqualizerFilter(boostRight))
        for index in 0...7 {
            EQright.append(AKEqualizerFilter(EQright[index]))
        }
        
        // Then, we apply panning to the EQ outputs, putting the EQleft's all to the left and EQright's all to the right
        let pan1 = AKPanner(EQleft[8], pan: -1)
        let pan2 = AKPanner(EQright[8], pan: 1)
        
        // Finally, we merge back both channels in a mixer node, which is is our output
        let mix = AKMixer(pan1, pan2)
        
        AudioKit.output = mix
        
        // We set the initial values for the EQs parameters and refresh the UI
        initEQ()
        
        try? AudioKit.start()
        
        mic?.stop()
    }
    
    public func setEarCanalCompensation(value: Bool) {
        if(value) {
            // Turns ear canal compensation on
            earCanalEQ1.start()
            earCanalEQ2.start()
            earCanalEQ3.start()
        } else {
            // Turns ear canal compensation off
            earCanalEQ1.stop()
            earCanalEQ2.stop()
            earCanalEQ3.stop()
        }
    }
    
    func initEQ() {
        // Sets up the initial parameters for the EQs
        for (index, eq) in EQleft.enumerated() {
            eq.centerFrequency = centerFrequencies[index]
            eq.bandwidth = bandwidths[index]
            eq.gain = 1
        }
        
        for (index, eq) in EQright.enumerated() {
            eq.centerFrequency = centerFrequencies[index]
            eq.bandwidth = bandwidths[index]
            eq.gain = 1
        }
    }
    
    public func start() {
        if(mic!.isStarted) {
            mic?.start()
        } else {
            print("Warning: Tried to start the AudioKit session, but it was already running")
        }
    }
    
    public func stop() {
        if(mic!.isStarted) {
            mic?.stop()
        } else {
            print("Warning: Tried to stop the AudioKit session, but it was not running")
        }
    }
    
    public func getGain(channel: Channel) -> [Float] {
        var gain = [Float]()
        switch channel {
        case .left:
            for eq in EQleft {
                gain.append(Float(20 * log10(eq.gain)))
            }
        case .right:
            for eq in EQright {
                gain.append(Float(20 * log10(eq.gain)))
            }
        }
        return gain
    }
    
    public func setSameGainForBothChannels() {
        for (index, eq) in EQright.enumerated() {
            eq.gain = EQleft[index].gain
        }
    }
    
    public func setAllGains(channel: Channel, setting: GainSetting) {
        let gain : [Double]
        switch(setting) {
        case .none:
            gain = gainNone
        case .mild:
            gain = gainMild
        case .moderate:
            gain = gainModerate
        case .severe:
            gain = gainSevere
        }
        
        switch(channel) {
        case .left:
            for (index, eq) in EQleft.enumerated() {
                eq.gain = gain[index]
            }
        case .right:
            for (index, eq) in EQright.enumerated() {
                eq.gain = gain[index]
            }
        }
    }

    public func setIndividualGain(channel: Channel, index: Int, gainDB: Float) {
        switch(channel) {
        case .left:
            EQleft[index].gain = pow(10, gainDB/20.0)
        case .right:
            EQright[index].gain = pow(10, gainDB/20.0)
        }
    }
    
    public func getMicAmplitude() -> Double {
        return tracker.amplitude
    }
}
