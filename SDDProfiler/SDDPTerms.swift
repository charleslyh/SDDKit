//
//  SDDPTerms.swift
//  SDDProfiler
//
//  Created by Charles on 2017/1/25.
//  Copyright © 2017年 Capsoul. All rights reserved.
//

import Foundation


class SDDPState: NSObject {
    let name: NSString
    
    private(set)
    var substates: [SDDPState] = []
    
    init(name: NSString) {
        self.name = name
        super.init()
    }
    
    func addSubstate(state: SDDPState) {
        substates.append(state)
    }
    
    func iterate(callback: ((SDDPState)->Void)) {
        var allStates = [self]
        while allStates.count > 0 {
            let state: SDDPState = allStates.first!
            allStates.remove(at: 0)
            allStates.append(contentsOf: state.substates)
            
            callback(state)
        }
    }
}

class SDDPTransition: NSObject {
    let from: SDDPState?
    let to:   SDDPState?
    
    init(fromState from: SDDPState?, toState to: SDDPState?) {
        assert((from != nil) || (to != nil), "From and To states can't be both nil in transition.")
        
        self.from = from
        self.to   = to
        super.init()
    }
    
    convenience init(initiallyTo to: SDDPState) {
        self.init(fromState: nil, toState: to)
    }
    
    convenience init(finallyFrom from: SDDPState) {
        self.init(fromState: from, toState: nil)
    }
}

class SDDPEvent: NSObject {
    let signal: NSString
    
    private(set)
    var transitions: [SDDPTransition] = []
    
    init(signal: NSString) {
        self.signal = signal
        super.init()
    }
    
    func add(transition: SDDPTransition) {
        transitions.append(transition)
    }
}

class SDDPDiagram: NSObject {
    private(set)
    var states: [SDDPState]
    var events: [SDDPEvent]
    
    init(states: [SDDPState], events: [SDDPEvent]) {
        self.states = states
        self.events = events
        super.init()
    }
}
