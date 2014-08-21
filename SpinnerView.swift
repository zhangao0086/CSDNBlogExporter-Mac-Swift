//
//  SpinnerView.swift
//  CSDNBlogExporter-Swift
//
//  Created by ZhangAo on 14-7-21.
//  Copyright (c) 2014年 ZA. All rights reserved.
//

import Cocoa

class SpinnerView: NSView {
    private var spinner = NSProgressIndicator()
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        let spinnerSize = CGSizeMake(40, 40)
        spinner.frame = CGRectMake((frame.size.width - spinnerSize.width) / 2,
                                   (frame.size.height - spinnerSize.height) / 2,
                                    spinnerSize.width, spinnerSize.height)
        spinner.style = NSProgressIndicatorStyle.SpinningStyle
        
        self.addSubview(spinner)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.lightGrayColor().CGColor
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimation(){
        self.layer?.hidden = false
        spinner.startAnimation(spinner)
    }
    
    func stopAnimation(){
        self.layer?.hidden = true
        spinner.stopAnimation(spinner)
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
}
