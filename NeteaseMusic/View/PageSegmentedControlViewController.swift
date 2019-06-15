//
//  PageSegmentedControlViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/6/8.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa

protocol PageSegmentedControlDelegate {
    func currentPage() -> Int
    func numberOfPages() -> Int
    
    func clickedPage(_ number: Int)
}

class PageSegmentedControlViewController: NSViewController {
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    
    @IBAction func clicked(_ sender: NSSegmentedControl) {
        guard let delegate = delegate else { return }
        
        var newPage = -1
        if let label = sender.label(forSegment: sender.selectedSegment),
            let pageNumber = Int(label) {
            newPage = pageNumber - 1
        } else {
            if sender.selectedSegment == 0 {
                newPage = currentPage - 1
            } else if sender.selectedSegment == sender.segmentCount - 1 {
                newPage = currentPage + 1
            } else {
                newPage = currentPage
            }
        }
        if newPage < 0 {
            newPage = 0
        }
        if newPage >= delegate.numberOfPages() {
            newPage = delegate.numberOfPages() - 1
        }
        
        guard newPage != currentPage else {
            // reset selected status to old value
            sender.setSelected(false, forSegment: sender.selectedSegment)
            var selectedIndex = -1
            for i in 0 ..< sender.segmentCount {
                if sender.label(forSegment: i) == "\(currentPage + 1)" {
                    selectedIndex = i
                }
            }
            sender.setSelected(true, forSegment: selectedIndex)
            return
        }
        
        delegate.clickedPage(newPage)
        initPageControl(delegate.numberOfPages(), currentPage: newPage)
    }
    
    var delegate: PageSegmentedControlDelegate?
    private var currentPage = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func reloadData() {
        guard let delegate = delegate else { return }
        initPageControl(delegate.numberOfPages(), currentPage: delegate.currentPage())
    }
    
    private func initPageControl(_ pageCount: Int, currentPage: Int) {
        guard currentPage >= 0, currentPage <= pageCount else { return }
        self.currentPage = currentPage
        let maxItemCount = 11
        let numberItemCount = maxItemCount - 2
        let omitted = pageCount > numberItemCount
        segmentedControl.segmentCount = 0
        segmentedControl.segmentCount = omitted ? maxItemCount : pageCount + 2
        
        
        let deviation = numberItemCount / 2
        
        let hideFrontPart = omitted && currentPage > deviation
        let hideBackPart = omitted && currentPage < (pageCount - deviation)
        
        var selectedIndex = -1
        for i in 0 ..< segmentedControl.segmentCount {
            switch i {
            case 0:
                // first item
                segmentedControl.setImage(NSImage(named: .init("icon.sp#icn-page_pre")), forSegment: i)
            case segmentedControl.segmentCount - 1:
                // last item
                segmentedControl.setImage(NSImage(named: .init("icon.sp#icn-page_next")), forSegment: i)
            case 2 where hideFrontPart:
                segmentedControl.setLabel("...", forSegment: i)
            case segmentedControl.segmentCount - 3 where hideBackPart:
                segmentedControl.setLabel("...", forSegment: i)
            case segmentedControl.segmentCount - 2:
                segmentedControl.setLabel("\(pageCount)", forSegment: i)
            case 1:
                segmentedControl.setLabel("1", forSegment: i)
            case _ where !hideFrontPart:
                segmentedControl.setLabel("\(i)", forSegment: i)
            case _ where i > 2 && !hideBackPart:
                let t = pageCount - (segmentedControl.segmentCount - 2 - i)
                segmentedControl.setLabel("\(t)", forSegment: i)
            case _ where i > 2 && hideFrontPart && hideBackPart:
                let t = currentPage + i - deviation
                segmentedControl.setLabel("\(t)", forSegment: i)
            default:
                break
            }
            
            if segmentedControl.label(forSegment: i) == "\(currentPage + 1)" {
                selectedIndex = i
            }
        }
        guard selectedIndex > 0, selectedIndex < (maxItemCount - 1) else { return }
        segmentedControl.setSelected(true, forSegment: selectedIndex)
    }
}
