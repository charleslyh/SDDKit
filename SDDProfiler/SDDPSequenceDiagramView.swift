//
//  SDDPSequenceDiagramView.swift
//  SDDProfiler
//
//  Created by Charles on 2017/1/23.
//  Copyright © 2017年 Capsoul. All rights reserved.
//

import Cocoa

extension Dictionary {
    mutating func merge(with dictionary: Dictionary) {
        dictionary.forEach { updateValue($1, forKey: $0) }
    }
    
    func merged(with dictionary: Dictionary) -> Dictionary {
        var dict = self
        dict.merge(with: dictionary)
        return dict
    }
}

extension NSString {
    func draw(in rect: NSRect, withTopOffset topOffset: CGFloat, attributes: [String : Any]? = nil) {
        let size = self.size(withAttributes: attributes)
        let centeredRect = NSRect(x: rect.origin.x,
                                  y: rect.origin.y + topOffset,
                                  width:  rect.size.width,
                                  height: size.height)
        self.draw(in: centeredRect, withAttributes: attributes)
    }
}

//MARK: Drawer

class SDDPDrawer: NSObject {
    private let context:    CGContext
    private let dirtyRect:  NSRect
    
    private let layouts:    SDDPLayouts
    private var topStates:  [SDDPState: SDDPState] = [:]
    
    init(context: CGContext, dirtyRect: NSRect, layouts: SDDPLayouts) {
        self.context   = context
        self.dirtyRect = dirtyRect
        self.layouts   = layouts
        super.init()
        
        for state in self.layouts.states {
            state.iterate { aState in
                topStates[aState] = state
            }
        }
    }
    
    private func drawRoundedRect(rect: NSRect, radius: CGFloat, borderColor: CGColor, fillColor: CGColor) {
        let path = CGMutablePath()
        
        path.addRoundedRect(in: rect, cornerWidth: radius, cornerHeight: radius)
        
        context.setLineWidth(1)
        context.setFillColor(fillColor)
        context.setStrokeColor(borderColor)
        
        context.addPath(path)
        context.drawPath(using: .fillStroke)
    }

    private func draw(_ state: SDDPState, withRect rect: NSRect) {
        drawRoundedRect(rect: rect, radius: 2, borderColor: NSColor.black.cgColor, fillColor: NSColor.white.cgColor)
        state.name.draw(in: rect, withTopOffset: SDDPLayouts.Padding, attributes: SDDPLayouts.stateAttributes)
    }
    
    private func drawStateHeader() {
        let path = CGMutablePath()
        
        path.addRect(NSMakeRect(dirtyRect.minX, 0, dirtyRect.maxX, layouts.headerHeight))
        context.setLineWidth(0)
        context.setFillColor(NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 0.3).cgColor)
        context.setStrokeColor(NSColor.clear.cgColor)
        context.addPath(path)
        context.drawPath(using: .fillStroke)
    }
    
    private func drawEventBar(withRect rect: NSRect, highlighted: Bool) {
        let path = CGMutablePath()
        path.addRect(rect)
        
        let hlAlpha: CGFloat = highlighted ? 0.05 : 0.1
        context.setFillColor(NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: hlAlpha).cgColor)
        context.setStrokeColor(NSColor.clear.cgColor)
        context.setLineWidth(0)
        context.addPath(path)
        context.drawPath(using: .fillStroke)
    }
    
    private func drawLifecycleLineForState(atPoint pt: NSPoint, withHeight height: CGFloat) {
        let path = CGMutablePath()
        path.move(to: pt)
        path.addLine(to: NSMakePoint(pt.x, pt.y + height))
        context.setLineWidth(1)
        context.setStrokeColor(NSColor.darkGray.cgColor)
        context.addPath(path)
        context.drawPath(using: .fillStroke)
    }
    
    //MARK: -
    private func drawBackground() {
        let path = CGMutablePath()
        path.addRect(dirtyRect)
        context.setLineWidth(0)
        context.setFillColor(NSColor.white.cgColor)
        context.setStrokeColor(NSColor.clear.cgColor)
        context.addPath(path)
        context.drawPath(using: .fillStroke)
    }

    private func drawStates() {
        for state in layouts.states {
            state.iterate { aState in
                draw(aState, withRect: layouts.stateRects[aState]!)
            }
        }
    }
    
    private func drawEventBars() {
        for i in 0..<layouts.events.count {
            let e = layouts.events[i]
            let makeRect = layouts.eventBarRectMakers[e]!
            let barRect  = makeRect(dirtyRect)
            let isOddRow = (i % 2 == 1)
            drawEventBar(withRect: barRect, highlighted: isOddRow)
        }
    }
    
    private func drawLifecycleLines() {
        for (state, rect) in layouts.stateRects {
            if state.substates.count != 0 {
                continue
            }
            
            drawLifecycleLineForState(atPoint: NSMakePoint(rect.midX, rect.midY), withHeight: layouts.canvasSize.height - rect.midY)
        }
    }
    
    private func drawSolidDot(atPoint point: NSPoint) {
        let DotLength: CGFloat = 3
        let path = CGMutablePath()
        path.addEllipse(in: NSMakeRect(point.x - DotLength / 2, point.y - DotLength / 2, DotLength, DotLength))
        context.setLineWidth(1)
        context.setStrokeColor(NSColor.black.cgColor)
        context.setFillColor(NSColor.black.cgColor)
        context.addPath(path)
        context.drawPath(using: .fillStroke)
    }
    
    private func drawTransitionArrow(atPoint point: NSPoint, leftToRight: Bool) {
        let ArrowWidth:  CGFloat = 6
        let ArrowHeight: CGFloat = 4
        
        let arrowDelta: CGFloat       = leftToRight ? -ArrowWidth : ArrowWidth
        let arrowOriginDelta: CGFloat = leftToRight ? -1 : 1
        let arrowOrigin = NSMakePoint(point.x + arrowOriginDelta, point.y)
        
        let path = CGMutablePath()
        path.move(to: arrowOrigin)
        path.addLine(to: NSMakePoint(point.x + arrowDelta, point.y - ArrowHeight / 2))
        path.addLine(to: NSMakePoint(point.x + arrowDelta, point.y + ArrowHeight / 2))
        path.closeSubpath()
        
        context.setLineWidth(1)
        context.setStrokeColor(NSColor.black.cgColor)
        context.setFillColor(NSColor.black.cgColor)
        context.addPath(path)
        context.drawPath(using: .fillStroke)
    }
    
    private func drawTransitionLine(fromPoint: NSPoint, toPoint: NSPoint, withSignal signal: NSString) {
        drawSolidDot(atPoint: fromPoint)
        
        let path = CGMutablePath()
        path.move(to: fromPoint)
        path.addLine(to: toPoint)
        context.setLineWidth(1)
        context.setStrokeColor(NSColor.black.cgColor)
        context.addPath(path)
        context.drawPath(using: .fillStroke)
        
        let fromLeft = fromPoint.x < toPoint.x
        drawTransitionArrow(atPoint: toPoint, leftToRight: fromLeft)
        
        var textOrigin = fromLeft ? fromPoint : toPoint
        let textSize = signal.size(withAttributes: SDDPLayouts.signalAttributes)
        textOrigin.y -= (textSize.height + 2)
        signal.draw(at: textOrigin, withAttributes: SDDPLayouts.signalAttributes)
    }
    
    private func drawSelfTransitionPolyline(aroundPoint point: NSPoint) {
        let PolylineLength: CGFloat = SDDPLayouts.EventBarHeight / 2
        
        let fromPoint = NSMakePoint(point.x, point.y - PolylineLength / 2)
        let toPoint   = NSMakePoint(point.x, point.y + PolylineLength / 2)
        
        drawSolidDot(atPoint: fromPoint)
        
        let path = CGMutablePath()
        path.move(to:fromPoint)
        path.addLine(to: NSMakePoint(fromPoint.x + PolylineLength, fromPoint.y))
        path.addLine(to: NSMakePoint(fromPoint.x + PolylineLength, toPoint.y))
        path.addLine(to:toPoint)
        
        context.setLineWidth(1)
        context.setStrokeColor(NSColor.black.cgColor)
        context.setFillColor(NSColor.clear.cgColor)
        context.addPath(path)
        context.drawPath(using: .fillStroke)
        
        drawTransitionArrow(atPoint: toPoint, leftToRight: false)
    }
    
    private func drawTransitions() {
        for i in 0..<layouts.events.count {
            let e = layouts.events[i]
            let makeRect = layouts.eventBarRectMakers[e]!
            let barRect  = makeRect(dirtyRect)
            let barCenterY = barRect.midY
            
            for t in e.transitions {
                var fromPoint: NSPoint!
                var toPoint: NSPoint!

                if t.from != nil {
                    let fromStateRect = layouts.stateRects[t.from!]!
                    fromPoint = NSMakePoint(fromStateRect.midX, barCenterY)
                } else {
                    let topRect = layouts.stateRects[self.topStates[t.to!]!]!
                    fromPoint = NSMakePoint(topRect.minX + SDDPLayouts.Padding, barCenterY)
                }
                
                if t.to != nil {
                    let toStateRect = layouts.stateRects[t.to!]!
                    toPoint = NSMakePoint(toStateRect.midX, barCenterY)
                } else {
                    let topRect = layouts.stateRects[self.topStates[t.from!]!]!
                    toPoint = NSMakePoint(topRect.minX + SDDPLayouts.Padding, barCenterY)
                }
                
                if t.from != t.to {
                    drawTransitionLine(fromPoint: fromPoint, toPoint: toPoint, withSignal: e.signal)
                } else {
                    drawSelfTransitionPolyline(aroundPoint: fromPoint)
                }
            }
        }
    }
    
    //MARK: - public methods
    func drawDiagram() {
        drawBackground()
        drawStateHeader()
        drawEventBars()
        drawLifecycleLines()
        drawStates()
        drawTransitions()
    }
}

class SDDPSequenceDiagramView: NSView {
    private var layouts: SDDPLayouts?
    
    func show(layouts: SDDPLayouts) {
        self.layouts = layouts
    
        self.setNeedsDisplay(self.bounds)
    }
    
    override var isFlipped: Bool {
        // Making left top as the origin
        return true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current()?.cgContext else {
            return
        }
        
        guard self.layouts != nil else {
            return
        }
        
        let drawer = SDDPDrawer(context: context, dirtyRect: dirtyRect, layouts: self.layouts!)
        drawer.drawDiagram()
    }
}
