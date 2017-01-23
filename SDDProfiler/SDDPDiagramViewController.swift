//
//  ViewController.swift
//  SDDProfiler
//
//  Created by Charles on 2017/1/23.
//  Copyright © 2017年 Capsoul. All rights reserved.
//

import Cocoa

class SDDPDiagramViewController: NSViewController {
    
    @IBOutlet var diagramView: SDDPSequenceDiagramView!
    @IBOutlet var scrollView:  NSScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        diagramView.show(layouts: sddp.layouts!)
        diagramView.frame = NSMakeRect(0, 0, sddp.layouts!.canvasSize.width, sddp.layouts!.canvasSize.height)
        
        scrollView.documentView = diagramView
    }
}

