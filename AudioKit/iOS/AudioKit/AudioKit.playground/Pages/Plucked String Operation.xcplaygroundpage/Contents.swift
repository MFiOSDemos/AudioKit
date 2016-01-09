//: [TOC](Table%20Of%20Contents) | [Previous](@previous) | [Next](@next)
//:
//: ---
//:
//: ## Plucked String Operation
//: ### Experimenting with a physical model of a string

import XCPlayground
import AudioKit

let audiokit = AKManager.sharedInstance

let playRate = 2.0

let randomNoteNumber = floor(AKOperation.randomNumberPulse(minimum: 12, maximum: 96, updateFrequency: 20))
let frequency = randomNoteNumber.midiNoteToFrequency()
let trigger = AKOperation.metronome(playRate)
let pluck = AKOperation.pluckedString(
    frequency: frequency,
    position: 0.2,
    pickupPosition: 0.1,
    reflectionCoefficent: 0.01,
    amplitude: 0.5)

let pluckNode = AKOperationGenerator(operation: pluck, triggered: true)

var distortion = AKDistortion(pluckNode)
distortion.finalMix = 0.5
distortion.decimationMix = 0
distortion.ringModMix = 0
distortion.softClipGain = 0

var delay  = AKDelay(distortion)
delay.time = 1.5 / playRate
delay.dryWetMix = 0.3
delay.feedback = 0.2

let reverb = AKReverb(delay)

//: Connect the sampler to the main output
audiokit.audioOutput = reverb
audiokit.start()

AKPlaygroundLoop(every: 1.0 / playRate) {
    pluckNode.trigger()
}

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

//: [TOC](Table%20Of%20Contents) | [Previous](@previous) | [Next](@next)
