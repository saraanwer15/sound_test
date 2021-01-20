//
//  ViewController.swift
//  sound_test
//
//  Created by Sara Anwer on 17/12/20.
//

import UIKit
import AVFoundation
import Accelerate
import CoreML

class ViewController: UIViewController, AVAudioRecorderDelegate {
    
    let audioEngine = AVAudioEngine()
    let audioSession = AVAudioSession.sharedInstance()
    var model = shvaas_sr44k()
    var inputIndex = 0
    var total_trigger_count = 0
    
    var inputData = try? MLMultiArray(shape:[1,131072], dataType:MLMultiArrayDataType.float32)
    var h = try? MLMultiArray(shape:[2,1,96], dataType:MLMultiArrayDataType.float32)
    var c = try?MLMultiArray(shape:[2,1,96],dataType:MLMultiArrayDataType.float32)
    
    func getVoice(output:MLMultiArray) -> Int{
        let n = (output.shape[1]).intValue
        let c = (output.shape[2]).intValue
        var freq = [0,0]
        var prev = 0
        var prev_prev = 0
        var trigger_count = 0
        for i in 0...n-1 {
            if i%8==0{
                if (freq[1]>=freq[0] && freq[1]>0){
                    if (prev != 1 && prev_prev != 1){
                        trigger_count+=1
                    }
                    prev_prev = prev
                    prev = 1
                }else{
                    prev_prev = prev
                    prev = 0
                }
                freq[0] = 0
                freq[1] = 0
            }
            var max:Double
            var maxIndex:Int
            max = Double(Int.min)
            maxIndex = 0
            for j in 0...c-1{
                let index = (i*output.strides[1].intValue)+j
                if output[index].doubleValue > max {
                    max = output[index].doubleValue
                    maxIndex = j
                }
            }
            freq[maxIndex]+=1
        }
        return trigger_count
    }
    
    @IBAction func StartButton(_ sender: UIButton) {
        let inputNode = audioEngine.inputNode
        let bus = 0
        inputNode.installTap(onBus: bus, bufferSize: 16384, format: inputNode.outputFormat(forBus: bus)) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
            let floatArray = UnsafeBufferPointer(start: buffer.floatChannelData![0],count:Int(buffer.frameLength))
            if(self.inputIndex >= 131072){
                guard let output = try? self.model.prediction(input_1: self.inputData!,h_0: self.h!,c_0: self.c!) else {
                                fatalError("Unexpected runtime error.")
                    }
                
                  let out = output._1252
                  for i in 0...191{
                    self.h![i] = output._1238[i]
                    self.c![i] = output._1239[i]
                   }
                self.total_trigger_count += self.getVoice(output: out)
                self.inputIndex = 0
            }else{
                var i = 0
                while(i<floatArray.count){
                    self.inputData![self.inputIndex] = NSNumber(value: floatArray[i])
                    self.inputIndex+=1
                    i+=1
                }
              }
           }
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
        print("**")
    }
    
    @IBAction func StopButton(_ sender: UIButton) {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        for i in 0...191{
            self.h![i] = 0
            self.c![i] = 0
        }
        print("audio stopped")
        print("Total Triggers count",self.total_trigger_count)
        let alert = UIAlertController(title: "Total Triggers count", message: String(self.total_trigger_count), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
        NSLog("The \"OK\" alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
        self.total_trigger_count = 0
        
    }
    
    
        override func viewDidLoad() {
        super.viewDidLoad()
            AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
                if hasPermission{
                    print("Accepted")
                }
            }
            for i in 0...191{
                self.h![i] = 0
                self.c![i] = 0
            }
        }

}
