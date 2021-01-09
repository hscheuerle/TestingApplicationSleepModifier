//
//  TestingApplicationSleepModifierApp.swift
//  TestingApplicationSleepModifier
//
//  Created by harry scheuerle on 1/8/21.
//

// Would brightness changed listeners trigger on this change.
// Is it worth checking and comparing to state change here to automatically set dimming levels.

import SwiftUI
import Combine

class ActivityData: ObservableObject {
    private var cancellable = Set<AnyCancellable>()
    @Published private var tap: Void = ()
    @Published private var dim: Void = ()
    @AppStorage("isDimmingEnabled") var isDimmingEnabled = false
    @AppStorage("dimmingDebounceSec") var dimmingDebounceSec: Int = 1 // just keep Int since more usable in user controls
    @AppStorage("activeBrightness") var activeBrightness: Double = Double(UIScreen.main.brightness)
    @AppStorage("dimmingBrightness") var dimmingBrightness: Double = Double(0.2 * UIScreen.main.brightness)
    // TODO: replace dimPub with dim state bool?, would work better with overlay to wake

    
    var dimPub: AnyPublisher<Void, Never> {
        $dim
            .filter { _ in self.isDimmingEnabled }
            .dropFirst()
            .eraseToAnyPublisher()
    }
    var tapPub: AnyPublisher<Void, Never> { $tap.dropFirst().eraseToAnyPublisher() }
    func tapInput() { self.tap = () }

    var dimWhenInactive: AnyCancellable {
        $tap
            .debounce(for: .seconds(self.dimmingDebounceSec), scheduler: RunLoop.main)
            .sink { self.dim = () }
    }
    
    init() { dimWhenInactive.store(in: &cancellable) }
}

struct CustomScreenControlModifier: ViewModifier {
    @StateObject var activityData = ActivityData()
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            ZStack {
                Color.clear
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Rectangle())
                
                content
            }
            
        }
        .simultaneousGesture(TapGesture().onEnded {
            activityData.tapInput()
        })
        .onReceive(activityData.tapPub, perform: {
            UIScreen.main.brightness = CGFloat(activityData.activeBrightness)
        })
        .onReceive(activityData.dimPub, perform: {
            UIScreen.main.brightness = CGFloat(activityData.dimmingBrightness)
        })
        .onAppear(perform: {
            UIApplication.shared.isIdleTimerDisabled = activityData.isDimmingEnabled
            UIScreen.main.brightness = CGFloat(activityData.activeBrightness)
        })
        .onChange(of: activityData.isDimmingEnabled, perform: { isEnabled in
            UIApplication.shared.isIdleTimerDisabled = isEnabled
        })
        .environmentObject(activityData)
        
    }
}

@main
struct TestingApplicationSleepModifierApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modifier(CustomScreenControlModifier())
        }
    }
}
