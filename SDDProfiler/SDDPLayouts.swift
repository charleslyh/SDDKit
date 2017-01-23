//
//  SDDPLayouts.swift
//  SDDProfiler
//
//  Created by Charles on 2017/1/25.
//  Copyright © 2017年 Capsoul. All rights reserved.
//

import Foundation
import Cocoa


typealias SDDPMakeEventBarRect = ((NSRect) -> NSRect)

class SDDPLayouts: NSObject {
    //MARK: classes
    static var stateAttributes: Dictionary<String, Any> {
        let font = NSFont.systemFont(ofSize: 12)
        let style = NSMutableParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
        style.alignment = .center
        
        return [
            NSFontAttributeName:           font,
            NSParagraphStyleAttributeName: style,
        ]
    }
    
    static var signalAttributes: Dictionary<String, Any> {
        let font = NSFont.systemFont(ofSize: 10)
        let style = NSMutableParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
        style.alignment = .left
        
        return [
            NSFontAttributeName:           font,
            NSParagraphStyleAttributeName: style,
        ]
    }
    
    static let Padding: CGFloat     = 8
    static let Margin: CGFloat      = 8
    static let ItemSpacing: CGFloat = 8
    static let EventBarHeight: CGFloat = 30
    
    static func layoutRects(with state: SDDPState, origin: NSPoint) -> [SDDPState: NSRect] {
        let textRect = state.name.boundingRect(with: NSZeroSize, options: [], attributes: stateAttributes)
        var mainRect = textRect
        mainRect.size.width  += Padding * 2  // for both left and right
        mainRect.size.height += Padding * 2  // for both top  and bottom
        
        var rects: [SDDPState: NSRect] = [:]
        if state.substates.count > 0 {
            var subWidth  = CGFloat(0)
            var subHeight = CGFloat(0)
            for substate in state.substates {
                let subrects = layoutRects(with: substate, origin: NSZeroPoint)
                let aRect = subrects[substate]!
                rects.merge(with: subrects)
                subWidth  += aRect.size.width
                subHeight = max(subHeight, aRect.size.height)
            }
            
            subWidth += (Padding * 2) + CGFloat(state.substates.count + 1) * Margin
            
            mainRect.size.width  = max(subWidth, mainRect.size.width)
            mainRect.size.height = textRect.size.height + subHeight + Margin + Padding * 2
        }
        
        func adjustSubRects(forState state: SDDPState) {
            let containingRect = rects[state]!
            var lastLeft =  containingRect.minX + Padding
            for substate in state.substates {
                var subrect = rects[substate]!
                let top = containingRect.maxY - Margin - subrect.size.height
                lastLeft += Margin
                subrect.origin = NSMakePoint(lastLeft, top)
                rects[substate] = subrect
                
                lastLeft = subrect.maxX
                
                adjustSubRects(forState: substate)
            }
        }
        
        mainRect.origin = origin
        rects[state] = mainRect
        adjustSubRects(forState: state)
        return rects
    }
    
    
    //MARK: - Instancees
    
    let states: [SDDPState]
    let events: [SDDPEvent]
    
    private(set) var stateRects:         [SDDPState: NSRect]  = [:]
    private(set) var eventBarRectMakers: [SDDPEvent: SDDPMakeEventBarRect] = [:]
    
    var headerHeight: CGFloat {
        return stateRects[self.states.first!]!.maxY + SDDPLayouts.Margin
    }
    
    var canvasSize: NSSize {
        var mostRight: CGFloat = 0
        for s in self.states {
            let rect = self.stateRects[s]!
            mostRight = max(mostRight, rect.maxX)
        }
        
        return NSMakeSize(mostRight + SDDPLayouts.Padding, headerHeight + CGFloat(events.count) * SDDPLayouts.EventBarHeight)
    }
    
    init(states: [SDDPState], events: [SDDPEvent]) {
        self.states = states
        self.events = events
        super.init()
    }
    
    private func layoutStates() {
        let fakeState = SDDPState(name: "")
        
        for state in self.states {
            fakeState.addSubstate(state: state)
        }
        
        let origin = NSMakePoint(SDDPLayouts.Margin, SDDPLayouts.Margin)
        self.stateRects = SDDPLayouts.layoutRects(with: fakeState, origin: origin)
        self.stateRects.removeValue(forKey: fakeState)
        
        var left: CGFloat = CGFloat.greatestFiniteMagnitude
        var top: CGFloat  = CGFloat.greatestFiniteMagnitude
        for (_, rect) in self.stateRects {
            left = min(left, rect.minX)
            top  = min(top,  rect.minY)
        }
        
        let deltaX = -left + origin.x
        let deltaY = -top  + origin.y
        
        for (state, rect) in self.stateRects {
            self.stateRects[state] = NSOffsetRect(rect, deltaX, deltaY)
        }
    }
    
    func layoutEventBars() {
        for i in 0..<events.count {
            let event = events[i]
            eventBarRectMakers[event] = { dirtyRect in
                return NSMakeRect(dirtyRect.minX, self.headerHeight + CGFloat(i) * SDDPLayouts.EventBarHeight, dirtyRect.size.width, SDDPLayouts.EventBarHeight)
            }
        }
    }
    
    func layoutDiagram() {
        layoutStates()
        layoutEventBars()
    }
}
