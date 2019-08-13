//
//  HLSimulatorViewController.swift
//  PlaybackAndEQ_v2
//
//  Created by Mark Steadman on 11/05/2017.
//  Copyright © 2017 Isaac. All rights reserved.
//

import UIKit
import AudioKit

class HLSimulatorViewController: UIViewController, UITextFieldDelegate {

    // AudioKit session singleton
    let session = AudioKitSession.sharedInstance
    
    // User interface
    //@IBOutlet var earSelector: UISegmentedControl!
    @IBOutlet var sliders: [UISlider]!
    @IBOutlet var textFields: [UITextField]!
    @IBOutlet var HLmodeButtons: [UIButton]!
    
    // Other types and variables
    enum EditMode {
        case left
        case right
        case both
    }
    var editMode : EditMode = .both
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Text fields delegates
        for (index, textField) in textFields.enumerated() {
            textField.tag = index
            textField.delegate = self
        }
        
        // Other UI elements
        for (index, slider) in sliders.enumerated() {
            slider.tag = index
            slider.addTarget(self, action: #selector(sliderMoved), for: .valueChanged)
        }
        
        for (index, button) in HLmodeButtons.enumerated() {
            button.tag = index
            button.addTarget(self, action: #selector (HLmodeButtonPressed), for: .touchUpInside)
        }
        
        // We refresh the UI
        updateUI()
    }
    
    func updateUI() {
        let gain : [Float]
        
        // First, we select one of the EQs depending on the 'editing mode'
        switch(editMode) {
        case .left:
            gain = session.getGain(channel: .left)
        case .right:
            gain = session.getGain(channel: .right)
        case .both:
            gain = session.getGain(channel: .left) // in case of both, we use left as reference (right should be equal to left)
        }
        
        // Then, we update the values for the sliders and text fields
        for (index, g) in gain.enumerated() {
            sliders[index].value = g
            textFields[index].text = String(Int(g.rounded()))
        }
    }
    
    @IBAction func earSelectorChanged(_ sender: UISegmentedControl) {
        // Changes the 'editing mode', which determines which EQ (left/right) is modified by interacting with the UI
        switch sender.selectedSegmentIndex {
        case 0:
            editMode = .left
        case 1:
            editMode = .right
        case 2:
            editMode = .both
            session.setSameGainForBothChannels()
        default:
            break
        }
        updateUI()
    }
    
    @objc func HLmodeButtonPressed(sender: UIButton) {
        // First, we select the setting depending on the button that was pressed
        let setting : GainSetting
        switch(sender.tag) {
        case 1:
            setting = .mild
        case 2:
            setting = .moderate
        case 3:
            setting = .severe
        default:
            setting = .none
        }
        
        // Then, depending on the edit mode (left/right/both) we change the corresponding EQ
        switch(editMode) {
        case .left:
            session.setAllGains(channel: .left, setting: setting)
        case .right:
            session.setAllGains(channel: .right, setting: setting)
        case .both:
            session.setAllGains(channel: .left, setting: setting)
            session.setAllGains(channel: .right, setting: setting)
        }
        
        updateUI()
    }
    
    @objc func sliderMoved(sender: UISlider) {
        let index = sender.tag
        let gain = sender.value
        
        // We update the text field
        textFields[index].text = String(Int(gain.rounded()))
        
        // We update the EQ gain
        switch(editMode) {
        case .left:
            session.setIndividualGain(channel: .left, index: index, gainDB: gain)
        case .right:
            session.setIndividualGain(channel: .right, index: index, gainDB: gain)
        case .both:
            session.setIndividualGain(channel: .left, index: index, gainDB: gain)
            session.setIndividualGain(channel: .right, index: index, gainDB: gain)
        }
    }
    
    // MARK: UITextField delegate
    
    // This function hides the keyboard after finishing editing text field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Hide the keyboard
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let index = textField.tag
        if var gain = Float(textField.text!) {
            // If a valid integer was used
            if gain > 20 {
                gain = 20
                textField.text = "20"
            }
            else if gain < -75 {
                gain = -75
                textField.text = "-75"
            }
            
            // We update the value in the slider
            sliders[index].value = gain
            
            // We update the EQ gain
            switch(editMode) {
            case .left:
                session.setIndividualGain(channel: .left, index: index, gainDB: gain)
            case .right:
                session.setIndividualGain(channel: .right, index: index, gainDB: gain)
            case .both:
                session.setIndividualGain(channel: .left, index: index, gainDB: gain)
                session.setIndividualGain(channel: .right, index: index, gainDB: gain)
            }
        }
        else {
            // If not a valid integer, leave the text field as it was before
            textField.text = String(Int(sliders[index].value.rounded()))
        }
    }

}

