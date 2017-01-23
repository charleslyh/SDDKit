//
//  SDDPLogsViewController.swift
//  SDDProfiler
//
//  Created by Charles on 2017/1/24.
//  Copyright © 2017年 Capsoul. All rights reserved.
//

import Cocoa

class SDDPLogsViewController: NSViewController {
    @IBOutlet
    var logsView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func parseLogsIntoDiagram() {
        var states: [SDDPState] = []
        var events: [SDDPEvent] = []
        
        let lines = logsView.string!.components(separatedBy: "\n")

        var name2state: [String: SDDPState] = [:]
        var existedSubNames: Set<String> = []
        
        let namePrefix = "\\[SDD\\]\\[((.*)\\(0x[\\da-f]+\\))\\]"
        
        let patternLaunch = "\(namePrefix)\\[L\\] \\{(.*)\\}"
        let regexLaunch   = try! NSRegularExpression(pattern: patternLaunch, options: [])
        
        let patternTrans  = "\(namePrefix)\\[T\\] <(.*)> \\| \\{(.*)\\} -> \\{(.*)\\}"
        let regexTrans    = try! NSRegularExpression(pattern: patternTrans, options: [])
        
        let patternStop = "\(namePrefix)\\[S\\] \\{(.*)\\}"
        let regexStop   = try! NSRegularExpression(pattern: patternStop, options: [])

        for line in lines {
            let matchesLaunching = regexLaunch.matches(in: line, options: [], range: NSRange(location: 0, length: line.characters.count))
            if matchesLaunching.count == 1 {
                let result = matchesLaunching.first!
                let rangeFull  = result.rangeAt(1)
                let fullName  = (line as NSString).substring(with: rangeFull)
                let rangeShort = result.rangeAt(2)
                let shortName = (line as NSString).substring(with: rangeShort)
                
                let topState = SDDPState(name: shortName as NSString)
                name2state[fullName] = topState
                states.append(topState)
                
                let range2 = result.rangeAt(3)
                let pathString = (line as NSString).substring(with: range2)
                let pathComponents = pathString.components(separatedBy: ",")
                let subName = pathComponents.last!
                
                let substateFullName = "\(fullName).\(subName)"
                existedSubNames.insert(substateFullName)
                
                let toState = SDDPState(name: subName as NSString)
                name2state[substateFullName] = toState
                
                topState.addSubstate(state: toState)
                
                let event = SDDPEvent(signal: "")
                event.add(transition: SDDPTransition(initiallyTo: toState))
                events.append(event)
                
                continue
            }
            
            let matchesTrans = regexTrans.matches(in: line, options: [], range: NSRange(location: 0, length: line.characters.count))
            if matchesTrans.count == 1 {
                let result = matchesTrans.first!
                let range1   = result.rangeAt(1)
                let fullName = (line as NSString).substring(with: range1)
                let topState = name2state[fullName]!
                
                // 2 for event name
                let eventRange = result.rangeAt(3)
                let signalName = (line as NSString).substring(with: eventRange)
                
                let sourceRange = result.rangeAt(4)
                let sourcePathString = (line as NSString).substring(with: sourceRange)
                let sourceComponents = sourcePathString.components(separatedBy: ",")
                let sourceName = sourceComponents.first!
                let fullSourceName = "\(fullName).\(sourceName)"
                let sourceState = name2state[fullSourceName]!
                
                let targetRange = result.rangeAt(5)
                let targetPathString = (line as NSString).substring(with: targetRange)
                let targetComponents = targetPathString.components(separatedBy: ",")
                let targetName = targetComponents.last!
                let fullTargetName = "\(fullName).\(targetName)"
                var targetState: SDDPState! = name2state[fullTargetName]
                if targetState == nil {
                    targetState = SDDPState(name: targetName as NSString)
                    name2state[fullTargetName] = targetState
                    
                    topState.addSubstate(state: targetState)
                }
                
                let event = SDDPEvent(signal: signalName as NSString)
                event.add(transition: SDDPTransition(fromState: sourceState, toState: targetState))
                events.append(event)
                
                continue
            }
            
            let matchesStop = regexStop.matches(in: line, options: [], range: NSRange(location: 0, length: line.characters.count))
            if matchesStop.count == 1 {
                let result = matchesStop.first!
                let fullRange = result.rangeAt(1)
                let fullName  = (line as NSString).substring(with: fullRange)
                
                let sourceRange = result.rangeAt(3)
                let sourcePathString = (line as NSString).substring(with: sourceRange)
                let sourceComponents = sourcePathString.components(separatedBy: ",")
                let sourceName = sourceComponents.first!
                let fullSourceName = "\(fullName).\(sourceName)"
                let sourceState = name2state[fullSourceName]!
                
                let event = SDDPEvent(signal: "")
                event.add(transition: SDDPTransition(finallyFrom: sourceState))
                events.append(event)
                continue
           }
        }
        
        sddp.diagram = SDDPDiagram(states: states, events: events)
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "Diagram" {
            parseLogsIntoDiagram()
        }
    }
    
}
