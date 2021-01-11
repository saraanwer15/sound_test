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
    
    var recordingSession:AVAudioSession!
    var audioRecorder:AVAudioRecorder!
    let audioEngine = AVAudioEngine()
    let audioSession = AVAudioSession.sharedInstance()
    var model = shvaas_sr44k()
    
    var h = try? MLMultiArray(shape:[2,1,96], dataType:MLMultiArrayDataType.float32)
    var c = try?MLMultiArray(shape:[2,1,96],dataType:MLMultiArrayDataType.float32)
    
    func getVoice(output:MLMultiArray) -> Int{
            let n = (output.shape[1]).intValue
            let c = (output.shape[2]).intValue

            var freq = [0,0]
            for i in 0...n-1 {
                if i%8==0{

                    if (freq[1]>=freq[0] && freq[1]>0){
                        print(1)
                    }else{
                        //print(0)
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
                if(maxIndex>0){
                    freq[maxIndex]+=1
                }
            }
            return 0
        }
    
    @IBAction func StartButton(_ sender: UIButton) {
        for i in 0...191{
            self.h![i] = 0
            self.c![i] = 0
        }
        let inputNode = audioEngine.inputNode
        let bus = 0
        /*let downMixer = AVAudioMixerNode()
        audioEngine.attach(downMixer)
        let format16KHzMono = AVAudioFormat.init(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 11025.0, channels: 1, interleaved: false)
        audioEngine.connect(downMixer, to: audioEngine.outputNode, format: format16KHzMono)
 */
        inputNode.installTap(onBus: bus, bufferSize: 131072, format: inputNode.outputFormat(forBus: bus)) {
                    (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
            let floatArray = UnsafeBufferPointer(start: buffer.floatChannelData![0],count:Int(buffer.frameLength))
           guard let inputdata = try? MLMultiArray(shape:[1,131072], dataType:MLMultiArrayDataType.float32) else{
                                    fatalError("Did not work")
                                }
           var i = 0
           while(i<floatArray.count){
                var j = 0
                while(j<131072 && i<floatArray.count){
                    inputdata[j] = NSNumber(value: floatArray[i])
                    //print(floatArray[i])
                    j+=1
                    i+=1
                 }
            //print(buffer.format.sampleRate)
                  guard let output = try? self.model.prediction(input_1: inputdata,h_0: self.h!,c_0: self.c!) else {
                                        fatalError("Unexpected runtime error.")
                       }
                    
                    

                  let out = output._1252
                  for i in 0...191{
                    self.h![i] = output._1238[i]
                    self.c![i] = output._1239[i]
                   }
                    self.getVoice(output: out)
            }
            
        }
        /*downMixer.outputVolume = 0.0
        let format = inputNode.inputFormat(forBus: 0)
        //I initialize a 16KHz format I need:
        let format16KHzMono = AVAudioFormat.init(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 11025.0, channels: 1, interleaved: false)
        audioEngine.connect(inputNode, to: downMixer, format: inputNode.inputFormat(forBus: 0))//use default input format
       audioEngine.connect(downMixer, to: audioEngine.outputNode, format: format16KHzMono)//use new audio format
 */
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
        print("****")
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

