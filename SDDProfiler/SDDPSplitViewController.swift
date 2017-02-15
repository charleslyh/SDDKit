//
//  SDDPSplitViewController.swift
//  SDDProfiler
//
//  Created by Charles on 2017/2/15.
//  Copyright © 2017年 Capsoul. All rights reserved.
//

import Cocoa

class SDDPDiagramSet: NSObject {
    let diagram: SDDPDiagram
    
    dynamic private(set) var layouts: SDDPLayouts!
    
    private var activeStates: Set<SDDPState> = []
    
    init(diagram: SDDPDiagram) {
        self.diagram = diagram
        super.init()
        self.reloadLayouts()
    }
    
    private func topState(of state: SDDPState) -> SDDPState {
        var topState = state
        while topState.parentState != nil {
            topState = topState.parentState!
        }
        return topState
    }
    
    private func shouldShow(_ state: SDDPState?) -> Bool {
        if state == nil {
            return false
        }
        
        return activeStates.contains(topState(of: state!))
    }
    
    private func shouldShow(_ transition: SDDPTransition) -> Bool {
        return shouldShow(transition.from) || shouldShow(transition.to)
    }
    
    private func activeEvents() -> [SDDPEvent] {
        var selectedEvents: [SDDPEvent] = []
        for event in diagram.events {
            let newEvent = SDDPEvent(signal: event.signal)
            for trans in event.transitions {
                if shouldShow(trans) {
                    newEvent.add(transition: trans)
                }
            }

            if newEvent.transitions.count > 0 {
                selectedEvents.append(newEvent)
            }
        }
        return selectedEvents
    }
    
    private func reloadLayouts() {
        let states = activeStates.sorted { (lhs, rhs) -> Bool in
            return self.diagram.states.index(of: lhs)! < self.diagram.states.index(of: rhs)!
        }
        
        let layouts = SDDPLayouts(states: states, events: activeEvents())
        layouts.layoutDiagram()
        
        self.layouts = layouts
    }
    
    func check(_ state: SDDPState, checked: Bool) {
        if checked {
            activeStates.insert(state)
        } else {
            activeStates.remove(state)
        }
        reloadLayouts()
    }
    
    func checked(_ state: SDDPState) -> Bool {
        return activeStates.contains(state)
    }
}

class SDDPSplitViewController: NSSplitViewController {
    
    private var diagramSet: SDDPDiagramSet!
    
    @IBOutlet weak var filtersViewItem: NSSplitViewItem!
    @IBOutlet weak var diagramViewItem: NSSplitViewItem!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        diagramSet = SDDPDiagramSet(diagram: sddp.diagram!)
        let filtersViewController = filtersViewItem.viewController as! SDDPFiltersViewController
        filtersViewController.diagramSet = diagramSet
        
        let diagramViewController = diagramViewItem.viewController as! SDDPDiagramViewController
        diagramViewController.diagramSet = diagramSet
    }
}
