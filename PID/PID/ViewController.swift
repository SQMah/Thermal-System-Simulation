//
//  ViewController.swift
//  PID
//
//  Created by Shao Qian MAH on 21/9/2017.
//  Copyright © 2017 Shao Qian MAH. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    // --- Simulation variables --- //
    
    //Temperature of environment
    var ambientTemperature = 20.0
    
    //Target temperature
    var setpoint = 18.0
    
    //Starting temperature of simulation
    let startingTemperature = 20.3
    
    //Minutes in between each sample
    let sampleTime: Double = 0.1
    
    //Minutes of simulation
    let runtime: Double = 5000.0
    
    //Mass of substance in container
    let massOfSubstance = 0.01 * 72 * 1.204 //0.01 is m^3 to L, the box holds 72 L, and the density of air (kg/m^3) at 20 C is 1.204
    
    //SHC of substance in container
    let specificHeatCapacityOfSubstance = 1000.0//1 kJ required to raise 1 kg of air temperature by 1 C, this is temperature dependent
    
    //Thermal conductivity of container
    let containerThermalConductivity = 0.03
    
    //Exterior area of box in m^2
    let containerArea = 1.4136
    
    //Maximum energy that cooling mechanism can dissipate per minute
    let energyMax = 7740.0 //Qmax (max heat pumping capacity) is 43 W, which is 43J/s, which is 2580 J/minute since there are 3, then there are 7740 J/min
    
    //PID constants
    let Kp = 0.5
    let Ki = 1.00
    let Kd = 1.00
    
    
   
    // --- Result variables --- //
    // ~~~Indexes of results correspond with time index~~~
    
    //Starting time (as a double)
    var time = [0.00]
    
    //Array storing power percentage calculated by PID
    var outputPower: Array<Double> = []
    
    //Array storing simulated results
    var simulatedTemperature: Array<Double> = []
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        createTimeArray(enablePrint: false)
        simulateEffect(enableExternalEnergyPrint: false, enableOutputPowerPrint: false, enableOutputEnergyPrint: true, enableEnergyChangePrint: false, enableTemperatureChangePrint: false, enableSimTempPrint: false)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func createTimeArray(enablePrint: Bool) {
        var i = 0
        if (enablePrint == true) {
            print(time[0])
        }
        // Create array separated by sample time interval up to the runtime of the simulation
        while (time[i] < runtime) {
            let tNum = ((sampleTime) + time[i]) * 100
            let tNumRound = tNum.rounded() / 100
            time.append(tNumRound)
            i = i + 1
            if (enablePrint == true) {
                print(tNumRound)
            }
        }
    }
    
    func pidOutput(measuredFunction: Array<Double>) -> Double {
        // Function u(t), finds derivative, integral and proportional error. Calculates INSTANTANEOUS OUTPUT
        var errorFunction: Array<Double> = []
        
        //Create error function
        var index = 0
        while (measuredFunction.endIndex > index) {
            errorFunction.append(measuredFunction[index] - setpoint)
            index = index + 1
        }
        
        //Find integral of function e(t)
        var i = 0
        let errorFunctionSize = errorFunction.endIndex
        var integralError = 0.0
       
        while (errorFunctionSize > i) {
            integralError = integralError + (errorFunction[i]) * sampleTime
            i = i + 1
        }
        
        //Find derivative of function e(t)
        var derivativeError = 0.0
        
        if (errorFunctionSize < 2) {
            // Not enough values to calculate derivative error, do not calculate
        } else {
            derivativeError = (errorFunction[errorFunctionSize - 1] - errorFunction[errorFunctionSize - 2])/sampleTime
        }
        
        //Find proportional error of e(t)
        let proportionalError = errorFunction[errorFunctionSize - 1]
        
        
        var pidOutput = Kp * proportionalError + Ki * integralError + Kd * derivativeError
       
        //Since pidOutput is a percentage of power supplied, limit maximum to 100 and minimum to zero
        if (pidOutput > 100) {
            pidOutput = 100
        } else if (pidOutput < 0) {
            pidOutput = 0
        }
        
        return pidOutput
    }
    
    func simulateEffect(enableExternalEnergyPrint:Bool, enableOutputPowerPrint: Bool,enableOutputEnergyPrint: Bool, enableEnergyChangePrint:Bool, enableTemperatureChangePrint: Bool, enableSimTempPrint: Bool) {
        var timeStep = 0
        
        //Set up first simulated temperature
        simulatedTemperature.append(startingTemperature)
        
        //Calculate first output value
        outputPower.append(pidOutput(measuredFunction: simulatedTemperature))
        
        while (time.endIndex > timeStep) {
            //Change of energy from loss/gain of energy to the room
            var i = 0
            var integralSimulatedTemperature = 0.0
            while (simulatedTemperature.endIndex > i) {
                //Find integral of simulated temperature
                integralSimulatedTemperature = integralSimulatedTemperature + simulatedTemperature[i] * sampleTime
                i = i + 1
            }
            //External energy is given as positive when temperature > ambient, as such needs to be subtracted from energy of thermoelectric coolers
            let externalEnergy = containerThermalConductivity * containerArea * (simulatedTemperature[timeStep] - ambientTemperature)
            if (enableExternalEnergyPrint) {
                print(externalEnergy)
            }
            
            //Change of energy from output
            //Proportional to output power
            
            let outputEnergy = energyMax * (outputPower[timeStep]/100) * sampleTime
            
            if (enableOutputPowerPrint) {
                print(outputPower[timeStep])
            }
            
            if (enableOutputEnergyPrint) {
                print(outputEnergy)
            }
            
            //Effect on system, using q=mc(deltaT), q/mc=deltaT
            let temperatureChange = ((outputEnergy + externalEnergy)/1000) / (specificHeatCapacityOfSubstance * massOfSubstance)
            simulatedTemperature.append(simulatedTemperature[timeStep] - temperatureChange)
            if (enableEnergyChangePrint) {
                print(outputEnergy + externalEnergy)
            }
            
            if (enableTemperatureChangePrint) {
                print(temperatureChange)
            }
            
            if (enableSimTempPrint) {
                print(simulatedTemperature[timeStep])
            }
            
            
            //Calculate new output and append to output array
            outputPower.append(pidOutput(measuredFunction: simulatedTemperature))
            timeStep = timeStep + 1
        }
    }
}
