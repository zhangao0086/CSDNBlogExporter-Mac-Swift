//
//  CSDNArticlesSummarySerializer.swift
//  CSDNBlogExporter-Swift
//
//  Created by ZhangAo on 14-7-22.
//  Copyright (c) 2014年 ZA. All rights reserved.
//

import Cocoa

class CSDNArticlesSummarySerializer: CSDNTracker {

    var username : String
    
    init(username: String) {
        self.username = username
        super.init()
        self.isGet = true
        self.requestURLString = "http://blog.csdn.net/" + self.username + "/article/list/9999?viewmode=contents"
        self.isBatchRequests = false
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!, error: AutoreleasingUnsafeMutablePointer<NSError?>) -> AnyObject? {
        let htmlString = NSString(data: data, encoding: NSUTF8StringEncoding)
        let pattern = try? NSRegularExpression(pattern: "list_view.*?link_title.*?href=\"(.*?)\">(.*?)</a>.*?link_postdate\">(.*?)</span>",
                                          options: NSRegularExpressionOptions.DotMatchesLineSeparators)
        let details : NSArray = htmlString!.matchesWithDetails(pattern)
        let articles : NSMutableArray = NSMutableArray(capacity: details.count)
        for match in details {
            let article = CSDNArticle()
            
            let articleURLString : NSString = ((match.groups as NSArray)[1] as! RxMatchGroup).value
            article.articleID = ((articleURLString.componentsSeparatedByString("/") as NSArray).lastObject as! NSString)
            article.articleTitle = ((match.groups as NSArray)[2] as! RxMatchGroup).value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet)
            article.publishTime = ((match.groups as NSArray)[3] as! RxMatchGroup).value
            articles.addObject(article)
        }
        return articles
    }
}
