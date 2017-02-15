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
    
    weak var diagramSet: SDDPDiagramSet! {
        didSet {
            diagramSet.addObserver(self, forKeyPath: "layouts", options: [.initial, .new], context: nil)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "layouts" {
            let layouts = diagramSet.layouts!
            diagramView.show(layouts: layouts)
            diagramHeight.constant = layouts.canvasSize.height
            diagramWidth.constant  = layouts.canvasSize.width
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.documentView = diagramView
    }
}

