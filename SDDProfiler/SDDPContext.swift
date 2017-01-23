//
//  SDDPGlobals.swift
//  SDDProfiler
//
//  Created by Charles on 2017/1/24.
//  Copyright © 2017年 Capsoul. All rights reserved.
//

import Foundation

class SDDPContext {
    var diagram: SDDPDiagram? {
        didSet {
            self.layouts = SDDPLayouts(states: diagram!.states, events: diagram!.events)
            self.layouts?.layoutDiagram()
        }
    }
    
    private(set)
    var layouts: SDDPLayouts?
}

let sddp = SDDPContext()
