//
//  RecorderViewController.swift
//  PlaybackAndEQ_v2
//
//  Created by Mark Steadman on 11/05/2017.
//  Copyright © 2017 Isaac. All rights reserved.
//

import UIKit
import AudioKit

class RecorderViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    // AudioKit session singleton
    let session = AudioKitSession.sharedInstance
    
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var playFileButton: UIButton!
    @IBOutlet var filePicker: UIPickerView!
    @IBOutlet var label: UILabel!
    
    var audioRecorder: AVAudioRecorder!
    var filePlayer: AKAudioPlayer!
    
    enum RecorderState {
        case ready
        case recording
        case playing
    }
    var recorderState: RecorderState = .ready
    
    var filePickerData: [URL] = [URL]()
    var selectedFileURL: URL? // currently selected file in the picker view
    var filePlayerIsInitialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Sets up picker view delegate and data source
        filePicker.delegate = self
        filePicker.dataSource = self
        
        // Get file names for file picker
        updateFileList()
        
    }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        switch recorderState {
        case .ready:
            let fileName = getFileNameFromDate() + ".caf"
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = documentDirectory.appendingPathComponent(fileName)
            
            let recordSettings = [AVFormatIDKey:kAudioFormatAppleIMA4,
                                  AVSampleRateKey:44100.0,
                                  AVNumberOfChannelsKey:2,AVEncoderBitRateKey:12800,
                                  AVLinearPCMBitDepthKey:16,
                                  AVEncoderAudioQualityKey:AVAudioQuality.max.rawValue
                                 ] as [String : Any]
            
            audioRecorder = try? AVAudioRecorder(url:url, settings: recordSettings)
            audioRecorder.record()
            
            recorderState = .recording
            DispatchQueue.main.async(){
                self.recordButton.setTitle("Stop", for: .normal)
                self.label.text = "Recording..."
            }
        case .recording:
            audioRecorder.stop()
            
            recorderState = .ready
            updateFileList()
            
            DispatchQueue.main.async(){
                self.recordButton.setTitle("Record", for: .normal)
                self.label.text = "Ready!"
            }
        case .playing:
            print("Cannnot record while playing")
            DispatchQueue.main.async() {
                self.label.text = "Cannnot record while playing"
            }
        }
    }
    
    @IBAction func playFileButtonPressed(_ sender: UIButton) {
        switch recorderState {
        case .ready:
            if selectedFileURL != nil {
                let audioFile = try? AKAudioFile(forReading: selectedFileURL!)
                
                // Open file
                if !filePlayerIsInitialized {
                    // If it's the first time, we need to call it this way
                    filePlayer = try? AKAudioPlayer(file: (audioFile)!)
                } else {
                    // If it's not the first time, this is faster
                    try? filePlayer.replace(file: audioFile!)
                }
                
                // Starts playing
                if filePlayer == nil {
                    print("Error opening file")
                    DispatchQueue.main.async() {
                        self.label.text = "Error opening file"
                    }
                } else {
                    if !filePlayerIsInitialized {
                        filePlayer?.completionHandler = playingFileEnded
                        session.mixer.connect(input: filePlayer!)
                        filePlayerIsInitialized = true
                    }
                    filePlayer?.start()
                    DispatchQueue.main.async(){
                        self.playFileButton.setTitle("Stop", for: .normal)
                        self.label.text = "Playing..."
                    }
                    recorderState = .playing
                }
            } else {
                print("There are no files to play")
                DispatchQueue.main.async() {
                    self.label.text = "There are no files to play"
                }
            }
        case .playing:
            filePlayer!.stop()
            DispatchQueue.main.async(){
                self.playFileButton.setTitle("Play", for: .normal)
                self.label.text = "Ready!"
            }
            recorderState = .ready
        case .recording:
            print("Cannot play while recording")
            DispatchQueue.main.async(){
                self.label.text = "Cannot play while recording"
            }
        }
    }
    
    @IBAction func deleteFileButtonPressed(_ sender: UIButton) {
        switch(recorderState) {
        case .ready:
            if filePickerData.count > 0 {
                do {
                    try FileManager.default.removeItem(at: selectedFileURL!)
                } catch {
                    print("Error: cannot remove file")
                    DispatchQueue.main.async() {
                        self.label.text = "Error: cannot remove file"
                    }
                }
                updateFileList()
            } else {
                print("There are no files to remove")
                DispatchQueue.main.async() {
                    self.label.text = "There are no files to remove"
                }
            }
        case .recording:
            print("Cannot delete while recording")
            DispatchQueue.main.async() {
                self.label.text = "Cannot delete while recording"
            }
        case .playing:
            print("Cannot delete while playing")
            DispatchQueue.main.async() {
                self.label.text = "Cannot delete while playing"
            }
        }

    }
    
    func playingFileEnded() {
        filePlayer?.stop()
        recorderState = .ready
        DispatchQueue.main.async(){
            self.playFileButton.setTitle("Play", for: .normal)
            self.label.text = "Ready!"
        }
    }
    
    @IBAction func volumeSliderChanged(_ sender: UISlider) {
        if(filePlayer != nil) {
            filePlayer.volume = Double(powf(10.0, sender.value))
        }
    }
    
    func getFileNameFromDate() -> String {
        let date = Date()
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        var fileName = "\(year)"
        if month < 10 {
            fileName = fileName + "0"
        }
        fileName = fileName + "\(month)"
        if day < 10 {
            fileName = fileName + "0"
        }
        fileName = fileName + "\(day)"
        if hour < 10 {
            fileName = fileName + "0"
        }
        fileName = fileName + "_\(hour)"
        if minutes < 10 {
            fileName = fileName + "0"
        }
        fileName = fileName + "\(minutes)"
        if seconds < 10 {
            fileName = fileName + "0"
        }
        fileName = fileName + "\(seconds)"
        
        return fileName
    }
    
    func updateFileList() {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        if let fileList = try? FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: [URLResourceKey]()) {
            // if directory exists, fileList is not null and it goes this way
            filePickerData = fileList.reversed() // this way the newest files are on the top
            if filePickerData.count > 0 {
                selectedFileURL = filePickerData[0]
                filePicker.selectRow(0, inComponent: 0, animated: true)
            } else {
                selectedFileURL = nil
            }
            filePicker.reloadAllComponents()
            filePicker.reloadInputViews()
        } else {
            // if directory does not exist, fileList is null and it goes this way
            print("Error: could not open directory")
            DispatchQueue.main.async(){
                self.label.text = "Error: could not open directory"
            }
        }
    }
    
    // MARK: UIPickerView data source and delegate
    
    // returns the number of 'columns' to display.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return filePickerData.count
    }
    
    // to display the text for the currently selected element
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filePickerData[row].lastPathComponent
    }
    
    // get the selected element
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if filePickerData.count > 0 {
            selectedFileURL = filePickerData[row]
        } else {
            selectedFileURL = nil
        }
    }


}

