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
    @IBOutlet var diagramHeight: NSLayoutConstraint!
    @IBOutlet var diagramWidth: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        diagramView.show(layouts: sddp.layouts!)
        diagramHeight.constant = sddp.layouts!.canvasSize.height
        diagramWidth.constant  = sddp.layouts!.canvasSize.width
        
        scrollView.documentView = diagramView
    }
}

