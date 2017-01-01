//
//  SwiftTimer.swift
//  SwiftTimer
//
//  Created by mangofang on 16/8/23.
//  
//  https://github.com/100mango/SwiftTimer
//
//  Modify the file name for LCTTimer on 16/12/19 by Alex.

import Foundation

public class LCTTimer {
    
    private let internalTimer: DispatchSourceTimer
    
    private var isRunning = false
    
    public let repeats: Bool
    
    public typealias LCTTimerHandler = (LCTTimer) -> Void
    
    private var handler: LCTTimerHandler
    
    public init(interval: DispatchTimeInterval, repeats: Bool = false, queue: DispatchQueue = .main , handler: @escaping LCTTimerHandler) {
        
        self.handler = handler
        self.repeats = repeats
        internalTimer = DispatchSource.makeTimerSource(queue: queue)
        internalTimer.setEventHandler { [weak self] in
            if let strongSelf = self {
                handler(strongSelf)
            }
        }
        
        if repeats {
            internalTimer.scheduleRepeating(deadline: .now() + interval, interval: interval)
        } else {
            internalTimer.scheduleOneshot(deadline: .now() + interval)
        }
    }
    
    public static func repeaticTimer(interval: DispatchTimeInterval, queue: DispatchQueue = .main , handler: @escaping LCTTimerHandler ) -> LCTTimer {
        return LCTTimer(interval: interval, repeats: true, queue: queue, handler: handler)
    }
    
    deinit {
        if !self.isRunning {
            internalTimer.resume()
        }
    }
    
    //You can use this method to fire a repeating timer without interrupting its regular firing schedule. If the timer is non-repeating, it is automatically invalidated after firing, even if its scheduled fire date has not arrived.
    public func fire() {
        if repeats {
            handler(self)
        } else {
            handler(self)
            internalTimer.cancel()
        }
    }
    
    public func start() {
        if !isRunning {
            internalTimer.resume()
            isRunning = true
        }
    }
    
    public func suspend() {
        if isRunning {
            internalTimer.suspend()
            isRunning = false
        }
    }
    
    public func rescheduleRepeating(interval: DispatchTimeInterval) {
        if repeats {
            internalTimer.scheduleRepeating(deadline: .now() + interval, interval: interval)
        }
    }
    
    public func rescheduleHandler(handler: @escaping LCTTimerHandler) {
        self.handler = handler
        internalTimer.setEventHandler { [weak self] in
            if let strongSelf = self {
                handler(strongSelf)
            }
        }

    }
}

//MARK: Throttle
public extension LCTTimer {
    
    private static var timers = [String:DispatchSourceTimer]()
    
    public static func throttle(interval: DispatchTimeInterval, identifier: String, queue: DispatchQueue = .main , handler: @escaping () -> Void ) {
        
        if let previousTimer = timers[identifier] {
            previousTimer.cancel()
        }
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.scheduleOneshot(deadline: .now() + interval)
        timer.setEventHandler {
            handler()
            timer.cancel()
            timers.removeValue(forKey: identifier)
        }
        timer.resume()
        timers[identifier] = timer
    }
}

//MARK: Count Down
public class LCTCountDownTimer {
    
    let internalTimer: LCTTimer
    
     var leftTimes: Int
    
     let originalTimes: Int
    
     let handler: (LCTCountDownTimer, _ leftTimes: Int) -> Void
    
    public init(interval: DispatchTimeInterval, times: Int,queue: DispatchQueue = .main , handler:  @escaping (LCTCountDownTimer, _ leftTimes: Int) -> Void ) {
        
        self.leftTimes = times
        self.originalTimes = times
        self.handler = handler
        self.internalTimer = LCTTimer.repeaticTimer(interval: interval, queue: queue, handler: { _ in
        })
        self.internalTimer.rescheduleHandler { [weak self]  LCTTimer in
            if let strongSelf = self {
                if strongSelf.leftTimes > 0 {
                    strongSelf.leftTimes = strongSelf.leftTimes - 1
                    strongSelf.handler(strongSelf, strongSelf.leftTimes)
                } else {
                    strongSelf.internalTimer.suspend()
                }
            }
        }
    }
    
    public func start() {
        self.internalTimer.start()
    }
    
    public func suspend() {
        self.internalTimer.suspend()
    }
    
    public func reCountDown() {
        self.leftTimes = self.originalTimes
    }
    
}

public extension DispatchTimeInterval {
    
    public static func fromSeconds(_ seconds: Double) -> DispatchTimeInterval {
        return .nanoseconds(Int(seconds * Double(NSEC_PER_SEC)))
    }
}
