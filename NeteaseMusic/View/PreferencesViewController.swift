//
//  PreferencesViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/9/19.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {
    @IBOutlet weak var gridView: NSGridView!
    @IBOutlet weak var playTextField: KeyEquivalentTextField!
    @IBOutlet weak var playGlobalTextField: KeyEquivalentTextField!
    
    @IBOutlet weak var preTextField: KeyEquivalentTextField!
    @IBOutlet weak var preGlobalTextField: KeyEquivalentTextField!
    
    @IBOutlet weak var nextTextField: KeyEquivalentTextField!
    @IBOutlet weak var nextGlobalTextField: KeyEquivalentTextField!
    
    @IBOutlet weak var volumeUpTextField: KeyEquivalentTextField!
    @IBOutlet weak var volumeUpGlobalTextField: KeyEquivalentTextField!
    
    @IBOutlet weak var volumeDownTextField: KeyEquivalentTextField!
    @IBOutlet weak var volumeDownGlobalTextField: KeyEquivalentTextField!
    
    @IBOutlet weak var likeTextField: KeyEquivalentTextField!
    @IBOutlet weak var likeGlobalTextField: KeyEquivalentTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gridView.subviews.compactMap {
            $0 as? KeyEquivalentTextField
        }.forEach {
            $0.placeholderString = "Empty"
            $0.keyEquivalentDelegate = self
            $0.delegate = self
        }
    }
    
    
}

extension PreferencesViewController: NSTextFieldDelegate, KeyEquivalentTextFieldDelegate {
    func keyEquivalentDidChanged(_ keyEquivalent: NSEvent) {
        print(keyEquivalent.modifierFlags)
        print(keyEquivalent.keyCode)
        
        
        
    }
}
