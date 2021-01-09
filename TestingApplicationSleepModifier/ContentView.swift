//
//  ContentView.swift
//  TestingApplicationSleepModifier
//
//  Created by harry scheuerle on 1/8/21.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var activityData: ActivityData
    
    var dimmingBinding: Binding<Bool> {
        .init(
            get: { self.activityData.isDimmingEnabled },
            set: {
                self.activityData.isDimmingEnabled = $0
                self.activityData.tapInput()
            }
        )
    }
    
    var brightnessBinding: Binding<Double> {
        .init(
            get: { self.activityData.activeBrightness },
            set: {
                self.activityData.activeBrightness = $0
                UIScreen.main.brightness = CGFloat($0)
                self.activityData.tapInput()
            }
        )
    }
    
    var dimnessBinding: Binding<Double> {
        .init(
            get: { self.activityData.dimmingBrightness },
            set: {
                self.activityData.dimmingBrightness = $0
                UIScreen.main.brightness = CGFloat($0)
                self.activityData.tapInput()
            }
        )
    }
    
    var body: some View {
        VStack {
            Toggle(isOn: dimmingBinding, label: { Text("Enabled") })
            Slider(value: brightnessBinding, in: 0...1, step: 0.001)
            Slider(value: dimnessBinding, in: 0...1, step: 0.001)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
