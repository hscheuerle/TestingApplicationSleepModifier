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
                self.activityData.tap = ()
                UIScreen.main.brightness = CGFloat($0)
            }
        )
    }
    
    var dimnessBinding: Binding<Double> {
        .init(
            get: { self.activityData.dimmingBrightness },
            set: {
                self.activityData.dimmingBrightness = $0
                self.activityData.dim = ()
                UIScreen.main.brightness = CGFloat($0)
            }
        )
    }
    
    @State var value: Double = 0
    
    var debounceTimeBinding: Binding<Double> {
        // TODO can do maths here to make slider more of a logarithmic value
        .init(
            get: { self.activityData.dimmingDebounceSec },
            set: {
                self.activityData.dimmingDebounceSec = $0
                self.activityData.update()
                self.activityData.tapInput()
                value = $0
            }
        )
    }
    
    @State var counter = 0
    
    // TODO: should restrict dim slider to be under wake slider? or just give warning message that behavior will be weird (guidelines)
    var body: some View {
        VStack {
            Button(action: { counter += 1 }) {
                Text("Overlay tester \(counter)")
            }
            Spacer().frame(minHeight: 50, maxHeight: 300)
            Toggle(isOn: dimmingBinding, label: { Text("Enabled") })
            Slider(value: brightnessBinding, in: 0...1, step: 0.001)
            Slider(value: dimnessBinding, in: 0...1, step: 0.001)
            Slider(value: debounceTimeBinding, in: 0.25...60, step: 0.25)
            Text("seconds: \(value)")
        }
        .onAppear {
            value = self.activityData.dimmingDebounceSec
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
