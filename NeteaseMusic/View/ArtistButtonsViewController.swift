//
//  ArtistButtonsViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 8/7/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Cocoa

class ArtistButtonsViewController: NSViewController {
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var stackView: NSStackView!
    
    @IBAction @objc func buttonAction(_ sender: IdButton) {
        ViewControllerManager.shared.selectSidebarItem(.artist, sender.id)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func removeAllButtons() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
    
    func initButtons(_ track: Track, small: Bool = false) {
        removeAllButtons()

        let buttons = track.artists.map { artist -> IdButton in
            let b = IdButton(title: artist.name, target: self, action: #selector(buttonAction(_:)))
            b.id = artist.id
            b.isEnabled = artist.id > 0
            
            if small {
                b.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            }
            return b
        }
        
        buttons.enumerated().forEach {
            stackView.addArrangedSubview($0.element)
            if $0.offset < (buttons.count - 1) {
                let textField = NSTextField(labelWithString: "/")
                textField.textColor = .tertiaryLabelColor
                if small {
                    textField.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
                }
                stackView.addArrangedSubview(textField)
            }
        }
    }
}
