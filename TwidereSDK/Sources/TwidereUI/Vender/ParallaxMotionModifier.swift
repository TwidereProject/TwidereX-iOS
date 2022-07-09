// https://trailingclosure.com/device-motion-effect/

import os.log
import SwiftUI
import CoreMotion

public struct ParallaxMotionModifier: ViewModifier {
    
    @ObservedObject public var manager: MotionManager
    public var magnitude: Double
    
    public init(
        manager: MotionManager,
        magnitude: Double
    ) {
        self.manager = manager
        self.magnitude = magnitude
    }
    
    public func body(content: Content) -> some View {
        content
            .offset(x: CGFloat(manager.roll * magnitude), y: CGFloat(manager.pitch * magnitude))
    }
}

public class MotionManager: ObservableObject {

    @Published public var pitch: Double = 0.0
    @Published public var roll: Double = 0.0
    
    private var manager: CMMotionManager

    public init() {
        self.manager = CMMotionManager()
        self.manager.deviceMotionUpdateInterval = 1/60
        self.manager.startDeviceMotionUpdates(to: .main) { [weak self] (motionData, error) in
            guard let self = self else { return }
            guard error == nil else {
                print(error!)
                return
            }

            if let motionData = motionData {
                self.pitch = motionData.attitude.pitch
                self.roll = motionData.attitude.roll
            }
        }
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
