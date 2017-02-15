//
//  SDDPFiltersViewController.swift
//  SDDProfiler
//
//  Created by Charles on 2017/2/15.
//  Copyright © 2017年 Capsoul. All rights reserved.
//

import Cocoa

class SDDPFiltersStateCellView: NSTableCellView {
    @IBOutlet weak var checkButton: NSButton!
    
    var toggleBlock: (() -> Void)!

    @IBAction func didTouchCheckButton(_ sender: NSButton) {
        toggleBlock()
    }
}

class SDDPFiltersViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var tableView: NSTableView!
    
    weak var diagramSet: SDDPDiagramSet! {
        didSet {
            tableView.reloadData()
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return diagramSet == nil ? 0 : diagramSet.diagram.states.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.make(withIdentifier: "StateCell", owner: nil) as? SDDPFiltersStateCellView {
            let state = diagramSet.diagram.states[row]
            cell.checkButton.title = state.name as String
            cell.checkButton.state = diagramSet.checked(state) ? NSOnState : NSOffState
            cell.toggleBlock = {
                let checked = cell.checkButton.state == NSOnState
                self.diagramSet.check(state, checked: checked)
            }
            
            return cell
        }
        return nil
    }
}
