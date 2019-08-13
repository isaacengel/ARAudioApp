//
//  MainViewController.swift
//  PlaybackAndEQ_v2
//
//  Created by Mark Steadman on 04/05/2017.
//  Copyright © 2017 Isaac. All rights reserved.
//

import UIKit
import AudioKit

class MainViewController: UIViewController {
    
    // AudioKit session singleton
    let session = AudioKitSession.sharedInstance
    
    // OSC manager singleton
    let osc = OSCManager.sharedInstance
    
    @IBOutlet var navigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        session.initialize()
    }
    
    @IBAction func mainSwitchChanged(_ sender: UISwitch) {
        if(sender.isOn) {
            session.start()
        } else {
            session.stop()
        }
    }
    
    @IBAction func earCanalCompensationSwitchChanged(_ sender: UISwitch) {
        if(sender.isOn) {
            session.setEarCanalCompensation(value: true)
        } else {
            session.setEarCanalCompensation(value: false)
        }
    }
    
    @IBAction func OSCSwitchChanged(_ sender: UISwitch) {
        if(sender.isOn) {
            osc.start()
        } else {
            osc.stop()
        }
    }
    
    @IBAction func countdownSwitchChanged(_ sender: UISwitch) {
        osc.enableCountdown(enable: sender.isOn)
    }
    
}
