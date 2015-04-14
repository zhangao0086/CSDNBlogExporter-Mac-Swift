//
//  AppDelegate.swift
//  CSDNBlogExporter-Swift
//
//  Created by ZhangAo on 14-7-21.
//  Copyright (c) 2014年 ZA. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate,NSUserNotificationCenterDelegate {
                            
    @IBOutlet var window: NSWindow!
    
    @IBOutlet var loginSheet: NSWindow!
    @IBOutlet var usernameField: NSTextField!
    @IBOutlet var passwordField: NSTextField!

    @IBOutlet var showLoginButton: NSButton!
    @IBOutlet var exportButton: NSButton!
    @IBOutlet var yamlCheckButton: NSButton!
    @IBOutlet var indicator: NSProgressIndicator!
    @IBOutlet var scrollView: NSScrollView!
    
    var messageTextView: NSTextView {
        get {
            return scrollView.contentView.documentView as! NSTextView
        }
    }
    
    var exportDirectoryURLString : NSString?
    
    lazy var spinner : SpinnerView = {
        return SpinnerView(frame: CGRectMake(0, 0, self.loginSheet!.frame.width, self.loginSheet!.frame.height))
    }()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        NSBundle.mainBundle().loadNibNamed("LoginPanel",owner:self,topLevelObjects:nil)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
    
    private func showTipsTitle(title: NSString?, content: NSString?) {
        var noti = NSUserNotification()
        noti.title = title as? String
        noti.informativeText = content as? String
        var notiCenter = NSUserNotificationCenter.defaultUserNotificationCenter()
        notiCenter.delegate = self
        notiCenter.deliverNotification(noti)
    }
    
    private func addMessageLog(message: NSString,_ args: CVarArgType...) {
        var originalString : NSString? = self.messageTextView.string
        var newString : NSString = ""
        var str = NSString(format: message as String, arguments: getVaList(args))
        
        if originalString!.length == 0 {
            newString = originalString!.stringByAppendingString(str as String)
        } else {
            newString = originalString!.stringByAppendingFormat("\n%@", str)
        }
        self.messageTextView.string = newString as String
        self.messageTextView.scrollRangeToVisible(
            NSMakeRange(newString.length,0))
    }
    
    private func insertYAMLHeaderForArticle(article: CSDNArticle!,fileContent: NSMutableString) {
        fileContent.appendString("---\n")
        fileContent.appendString("layout: contentpage\n")
        fileContent.appendFormat("title: %@\n",article.articleTitle!)
        if article.categories != nil {
            fileContent.appendFormat("categories: [%@]\n",article.categories!)
        }
        if article.tags != nil {
            fileContent.appendFormat("tags: [%@]\n",article.tags!)
        }
        fileContent.appendFormat("date: %@:%02d\n",article.publishTime!,rand() % 60)
        fileContent.appendFormat("sourceType: %d",article.sourceType.rawValue)
        fileContent.appendString("---\n")
        fileContent.appendString("\n")
    }
    
    private func saveArticle(article: CSDNArticle) {
        addMessageLog("----正在导出《%@》----已导出",article.articleTitle!)
        assert(article.rawContent != nil)
        
        var fileContent: NSMutableString = NSMutableString()
        if self.yamlCheckButton.state == NSOnState {
            insertYAMLHeaderForArticle(article, fileContent: fileContent)
        }
        fileContent.appendString(article.rawContent! as String)
        
        var fileNamePrefix: NSString = article.publishTime?.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())[0] as! NSString
        var fileName: NSString = article.articleTitle!.stringByReplacingOccurrencesOfString(" ", withString: "-")
        var fullFileName = NSString(format: "%@-%@.html", fileNamePrefix,fileName)
        var filePath = self.exportDirectoryURLString?.stringByAppendingPathComponent(fullFileName as String)
        
        var error: NSError?
        var success: Bool = fileContent.writeToFile(filePath!, atomically: true, encoding: NSUTF8StringEncoding, error: &error)
        if !success {
            NSLog("%@", error!.localizedDescription)
        }
        self.addMessageLog("----已导出至《%@》", fullFileName)
    }
    
    private func startExporting() {
        if self.showLoginButton.enabled {
            self.showTipsTitle("提示", content: "请先登录")
            return
        }
        addMessageLog("开始导出...\n正在访问指定的博客...")
        indicator?.startAnimation(indicator)
        
        var articlesSummarySerializer = CSDNArticlesSummarySerializer(username: usernameField.stringValue)
        articlesSummarySerializer.sendRequest(
            {(object: AnyObject!, isBatchCompleted: Bool) -> Void in
                var articles : Array<CSDNArticle> = object as! Array<CSDNArticle>
                self.indicator.doubleValue = 10.0
                self.indicator.indeterminate = false
                self.addMessageLog("已获取所有文章的摘要信息")
                
                for summary in articles {
                    var title : NSString = summary.articleTitle!
                    self.addMessageLog("----%@", title)
                }
                self.addMessageLog("共%d篇文章", articles.count)
                self.addMessageLog("开始导出每一篇文章...")
                var articlesSerializer = CSDNArticleSerializer(articlesSummary: articles)
                var i = 0
                articlesSerializer.sendRequest(
                    {(object: AnyObject!, isBatchCompleted: Bool) in
                        if isBatchCompleted {
                            self.indicator.doubleValue = 100.0
                            self.addMessageLog("导出完成")
                            self.addMessageLog("已成功导出%d篇", i)
                        } else {
                            i++
                            self.indicator.incrementBy(90.0 / Double(articles.count))
                            self.saveArticle(object as! CSDNArticle)
                        }
                    }
                    , failedBlock:
                    {error in
                        self.showTipsTitle("提示", content: errorMessageInError(error))
                    })
            }, failedBlock:
            {error in
                self.showTipsTitle("提示", content: errorMessageInError(error))
            })
    }
    
    @IBAction func showLoginPanel(sender: AnyObject) {
        window.beginSheet(loginSheet, completionHandler:
            {returnCode in
                self.loginSheet!.orderOut(self)
            })
    }
    
    @IBAction func endLoginPanel(sender: AnyObject?) {
        window.endSheet(loginSheet, returnCode: NSCancelButton)
    }
    
    @IBAction func exportButtonClicked(sender: NSButton) {
        var openDLG = NSOpenPanel()
        openDLG.canChooseDirectories = true
        openDLG.canCreateDirectories = true
        openDLG.canChooseFiles = false
        openDLG.allowsMultipleSelection = false
        
        if openDLG.runModal() == NSOKButton {
            sender.enabled = false
            exportDirectoryURLString = openDLG.URL!.relativePath
            self.startExporting()
        }
    }
    
    @IBAction func login(sender: AnyObject) {
        if usernameField.stringValue.isEmpty {
            showTipsTitle("提示", content: "用户名不能为空")
            return
        }
        if passwordField.stringValue.isEmpty {
            showTipsTitle("提示", content: "密码不能为空")
            return
        }
        loginSheet?.contentView.addSubview(self.spinner)
        spinner.startAnimation()
        
        var loginSerializer = CSDNLoginSerializer()
        loginSerializer.username = usernameField.stringValue
        loginSerializer.password = passwordField.stringValue
        loginSerializer.sendRequest(
            {(object: AnyObject?,isBatchCompleted: Bool) in
                self.spinner.stopAnimation()
                self.endLoginPanel(self.loginSheet)
                self.showLoginButton.enabled = false
                self.exportButton.enabled = true
                self.yamlCheckButton.enabled = true
                self.passwordField.stringValue = ""
                self.showLoginButton.title = self.usernameField.stringValue
                self.showLoginButton.sizeToFit()
            },
            failedBlock:
            {(error: NSError!) in
                self.spinner.stopAnimation()
                self.showTipsTitle("提示", content: errorMessageInError(error))
            })
    }
}

