//
//  CSDNLoginSerializer.swift
//  CSDNBlogExporter-Swift
//
//  Created by ZhangAo on 14-7-21.
//  Copyright (c) 2014年 ZA. All rights reserved.
//

import Cocoa

class CSDNLoginSerializer: CSDNTracker {

    var username : NSString = ""
    var password : NSString = ""

    init() {
        super.init()
        self.isGet = false
        self.isBatchRequests = false
    }
    
    func errorMessageForHtmlString(htmlString: NSString) -> NSString? {
        var errorMessage : NSString? = htmlString.firstMatch(NSRegularExpression(pattern: "(?<=error-message\">).*?(?=<)"))
        return errorMessage
    }
    
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!, error: NSErrorPointer) -> AnyObject! {
        var htmlString = NSString(data: data, encoding: NSUTF8StringEncoding)
        var errorMessage : NSString? = errorMessageForHtmlString(htmlString)
        if !errorMessage {
            return htmlString
        } else {
            error.memory = NSError(domain: "CSDN", code: 999, userInfo: ["errorMessage" : errorMessage!])
            return nil
        }
    }
    
    func requestURLString() -> NSString  {
        return "https://passport.csdn.net/account/login"
    }
    
    func requestURLStrings() -> NSArray? {
        return nil
    }

    func ltTokenByHtmlString(htmlString : NSString) -> NSString {
        var ltToken = htmlString.firstMatch(NSRegularExpression(pattern: "(?<=\"lt\" value=\").*?(?=\")")) as NSString
        return ltToken
    }
    
    func executionByHtmlString(htmlString : NSString) -> NSString {
        var execution = htmlString.firstMatch(NSRegularExpression(pattern: "(?<=\"execution\" value=\").*?(?=\")")) as NSString
        return execution
    }
    
    func postParams() -> NSDictionary {
        var request = NSURLRequest(URL: NSURL(string: self.requestURLString))
        var data = NSURLConnection.sendSynchronousRequest(request,
            returningResponse: nil, error: nil)
        var htmlString = NSString(data: data, encoding: NSUTF8StringEncoding)
        return [
            "username": username,
            "password": password,
            "lt": ltTokenByHtmlString(htmlString),
            "execution": executionByHtmlString(htmlString),
            "_eventId": "submit"
        ]
    }
}
