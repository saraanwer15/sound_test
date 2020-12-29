//
//  ViewController.swift
//  sound_test
//
//  Created by Sara Anwer on 17/12/20.
//

import UIKit
import AVFoundation
import CoreML

class ViewController: UIViewController, AVAudioRecorderDelegate {
    
    var recordingSession:AVAudioSession!
    var audioRecorder:AVAudioRecorder!
    let audioEngine = AVAudioEngine()
    let audioSession = AVAudioSession.sharedInstance()
    
    @IBAction func StartButton(_ sender: UIButton) {
        let inputNode = audioEngine.inputNode
                let bus = 0
        inputNode.installTap(onBus: bus, bufferSize: 176400, format: inputNode.inputFormat(forBus: bus)) {
                    (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
               /*var i = 0
               while(i < buffer.frameLength) {
                print(buffer.floatChannelData?[0][i])
                    i=i+1
                }
                */
            //print(buffer.floatChannelData)
                }

                audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
    }
    
    @IBAction func StopButton(_ sender: UIButton) {
        audioEngine.stop()
        print("audio stopped")
    }
    
    
        override func viewDidLoad() {
        super.viewDidLoad()
            recordingSession = AVAudioSession.sharedInstance()
            AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
                if hasPermission{
                    print("Accepted")
                }
            }
        }

}

