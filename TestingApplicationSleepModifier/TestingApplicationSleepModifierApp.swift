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
    @Published var tap: Void = ()
    @Published var dim: Void = ()
    @AppStorage("isDimmingEnabled") var isDimmingEnabled = false
    @AppStorage("dimmingDebounceSec") var dimmingDebounceSec: Double = 1
    @AppStorage("activeBrightness") var activeBrightness: Double = Double(UIScreen.main.brightness)
    @AppStorage("dimmingBrightness") var dimmingBrightness: Double = Double(0.2 * UIScreen.main.brightness)
    
    var dimPub: AnyPublisher<Void, Never> {
        $dim
            .filter { _ in self.isDimmingEnabled }
            .dropFirst()
            .eraseToAnyPublisher()
        
    }
    
    var tapPub: AnyPublisher<Void, Never> {
        $tap
            .dropFirst()
            .eraseToAnyPublisher()
        
    }
    
    var screenIsActive: AnyPublisher<Bool, Never> {
        Publishers
            .Merge(
                // Just(true), // Test this
                tapPub.map { _ in true },
                dimPub.map { _ in false}
            )
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    func tapInput() { self.tap = () }

    var dimWhenInactive: AnyCancellable {
        $tap
            .debounce(for: .seconds(self.dimmingDebounceSec), scheduler: RunLoop.main)
            .sink { self.dim = () }
    }
    
    init() {
        dimWhenInactive.store(in: &cancellable)
    }
    
    func update() {
        cancellable.removeAll()
        dimWhenInactive.store(in: &cancellable)
    }
}

struct CustomScreenControlModifier: ViewModifier {
    @StateObject var activityData = ActivityData()
    @State var isOverlayEnabled = false
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            ZStack {
                content
                
                Color.clear
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Rectangle())
                    .allowsHitTesting(isOverlayEnabled)
                    .onTapGesture {
                        activityData.tapInput()
                    }
            }
            
        }
        .simultaneousGesture(TapGesture().onEnded {
            // TODO: will long press min duration 0 work better for dragging controls?
            activityData.tapInput()
        })
        .onReceive(activityData.screenIsActive, perform: { isActive in
            isOverlayEnabled = !isActive
        })
        .onReceive(activityData.screenIsActive, perform: { isActive in
            UIScreen.main.brightness = CGFloat(isActive ? activityData.activeBrightness : activityData.dimmingBrightness)
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
