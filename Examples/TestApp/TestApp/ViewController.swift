//
//  ViewController.swift
//  TestApp
//
//  Created by Aurelius Prochazka on 9/29/15.
//
//

import UIKit
import Foundation
import AudioKit

class ViewController: UIViewController {

    let audiokit = AKManager.sharedInstance
    let input = AKMicrophone()
    var delay:  AKDelay?
    var moog:   AKMoogLadder?
    var bandPassFilter: AKBandPassButterworthFilter?
    var allpass: AKFlatFrequencyResponseReverb?
    var reverb: AKReverb?
    var jcReverb: AKChowningReverb?
    var verb2: AKReverb2?
    var limiter: AKPeakLimiter?
    var midi = AKMidi()
    var fmOsc = AKFMOscillator()
    var exs = AKSampler()
    var exs2 = AKSampler()
    var osc = AKOscillator()
    var midiInst:AKFMOscillatorInstrument?
    var seq = AKSequencer(filename:"4tracks")
    var mixer = AKMixer()
//    var spatMix = AKSpatialMixer()

    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        moog    = AKMoogLadder(input)
        delay   = AKDelay(moog!)
//        allpass = AKFlatFrequencyResponseReverb(moog!)//, loopDuration: 0.1)
        verb2  = AKReverb2(delay!)
        limiter = AKPeakLimiter(verb2!)
        //if let reverb = reverb { reverb.loadFactoryPreset(.Cathedral) }
        audiokit.audioOutput = limiter
        //print(verb2?.internalAudioUnit.debugDescription)
        //getAUParams((limiter?.internalAU)!)

        */
//        exs.loadEXS24("Sounds/sawPiano1")
//        exs2.loadWav("Sounds/kylebell1-shrt")
        
        let sawtooth = AKTable(.Sawtooth, size: 16)
        for value in sawtooth.values { value }
        midiInst = AKFMOscillatorInstrument(numVoicesInit: 4)
        mixer.connect(midiInst!)
//        mixer.connect(exs2)
        moog    = AKMoogLadder(mixer)
        verb2  = AKReverb2(moog!)
        audiokit.audioOutput = verb2

//        seq = AKSequencer(filename: "4tracks", engine: audiokit.engine)
        audiokit.start()

        midi.openMidiOut("Session 1")
//        midi.openMidiIn("Session 1")
        let defaultCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()
        defaultCenter.addObserverForName(AKMidiStatus.ControllerChange.name(), object: nil, queue: mainQueue, usingBlock: midiNotif)

        defaultCenter.addObserverForName(AKMidiStatus.NoteOn.name(), object: nil, queue: mainQueue, usingBlock: midiNoteNotif)

        midiInst!.enableMidi(midi.midiClient, name: "PolyOsc")
        seq.setGlobalMidiOutput((midiInst?.midiIn)!)
//        print(seq.numTracks)
        //seq.tracks[1].addNote(36, vel: 127, position: 0, dur: 1.1) //purposefully adding a note that is too long to show it gets truncated
        seq.setLength(4) //truncates above note
        //seq.debug()
        print(seq.tracks[1].length)
    }

    func midiNotif(notif:NSNotification){
        print(notif.userInfo!)
        exs.playNote(Int(arc4random_uniform(127)))
        exs2.playNote(Int(arc4random_uniform(127)))
    }

    func midiNoteNotif(notif:NSNotification){
        midiInst?.handleMidiNotif(notif)
        //exs.playNote(Int((notif.userInfo?["note"])! as! NSNumber))
        //exs2.playNote(Int((notif.userInfo?["note"])! as! NSNumber))
//        exs2.playNote(notif.userInfo?.indexForKey("note"))
    }
    @IBAction func playNote(){
//        exs.playNote(63)
//        exs.playNote(Int(arc4random_uniform(127)))
        seq.play()
    }
    @IBAction func playNote2(){
                seq.rewind()
//        exs2.playNote(60)
//        exs2.playNote(Int(arc4random_uniform(127)))
    }
    @IBAction func playNoteboth(){
        seq.loopToggle()
        print(seq.loopEnabled)
//        exs.playNote(Int(arc4random_uniform(127)))
//        exs2.playNote(Int(arc4random_uniform(127)))
    }
    @IBAction func midiPanic(){
        midiInst?.panic()
    }
    @IBAction func connectMidi(){
        midi.openMidiOut("Session 1")
    }
    @IBAction func sendMidi(){
        let event = AKMidiEvent.eventWithNoteOn(33, velocity: 127, channel: 0)
        midi.sendMidiEvent(event)
    }
    @IBAction func sendMidiController(sender: UISlider){
        let event = AKMidiEvent.eventWithController(33, val: UInt8(sender.value * 127), channel: 0)
        midi.sendMidiEvent(event)
    }
    @IBAction func changeReverb(sender: UISlider) {
        guard let reverb = verb2 else { return }
//        reverb.dryWetMix = Double(100.0 * sender.value)
        midiInst?.modulationIndex = Double(10.0*sender.value)
    }
    @IBAction func changeDelayTime(sender: UISlider) {
        //if let delay = delay { delay.delayTime = NSTimeInterval(sender.value) }
        print("\(norm2value(Double(sender.value), loLimit: 0.001, hiLimit: 20000, taper: 10))")
    }
    @IBAction func changeCutoff(sender: UISlider) {
        guard let moog = moog else { return }
        moog.cutoffFrequency = Double(sender.value * 10000.0)
    }
    @IBAction func changeResonance(sender: UISlider) {
        guard let moog = moog else { return }
        moog.resonance = Double(sender.value * 0.98)
    }
    @IBAction func changeReverbDuration(sender: UISlider) {
//        guard let allpass = allpass else { return }
//        allpass.reverbDuration = sender.value * 5.0
        guard let verb = verb2 else {return}
        verb.decayTimeAt0Hz = Double(sender.value * 20.0)
        verb.decayTimeAtNyquist = Double(sender.value * 20.0)
    }
    func getAUParams(inputAU: AudioUnit)->([AudioUnitParameterInfo]){
        //  Get number of parameters in this unit (size in bytes really):
        var size: UInt32 = 0
        var propertyBool = DarwinBoolean(true)

        AudioUnitGetPropertyInfo(inputAU, kAudioUnitProperty_ParameterList, kAudioUnitScope_Global, 0, &size, &propertyBool)
        let numParams = Int(size)/sizeof(AudioUnitParameterID)
        var parameterIDs = [AudioUnitParameterID](count: Int(numParams), repeatedValue: 0)
        AudioUnitGetProperty(inputAU, kAudioUnitProperty_ParameterList, kAudioUnitScope_Global, 0, &parameterIDs, &size)
        var paramInfo = AudioUnitParameterInfo()
        var outParams = [AudioUnitParameterInfo]()
        var parameterInfoSize:UInt32 = UInt32(sizeof(AudioUnitParameterInfo))
        for paramID in parameterIDs{
            AudioUnitGetProperty(inputAU, kAudioUnitProperty_ParameterInfo, kAudioUnitScope_Global, paramID, &paramInfo, &parameterInfoSize)
            outParams.append(paramInfo)
            print(paramID)
            print("Paramer name :\(paramInfo.cfNameString?.takeUnretainedValue()) | Min:\(paramInfo.minValue) | Max:\(paramInfo.maxValue) | Default: \(paramInfo.defaultValue)")
        }
        return outParams
    }//getAUParams
}

