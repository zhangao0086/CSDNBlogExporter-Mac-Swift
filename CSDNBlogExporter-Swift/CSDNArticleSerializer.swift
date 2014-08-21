//
//  CSDNArticleSerializer.swift
//  CSDNBlogExporter-Swift
//
//  Created by ZhangAo on 14-7-22.
//  Copyright (c) 2014年 ZA. All rights reserved.
//

import Cocoa

class CSDNArticleSerializer: CSDNTracker {

    var articlesSummary : Array<CSDNArticle>
    
    override var requestURLStrings : Array<String>? {
        get {
            var urlStrings = [String](count: articlesSummary.count, repeatedValue: "")
            var i = 0
            for articleSummary: CSDNArticle in articlesSummary {
                urlStrings[i++] = "http://write.blog.csdn.net/postedit/" + articleSummary.articleID!
            }
            return urlStrings
        }
        set {
            super.requestURLStrings = newValue
        }
    }
    
    init(articlesSummary: Array<CSDNArticle>) {
        self.articlesSummary = articlesSummary
        super.init()
        self.isGet = false
        self.isBatchRequests = true
    }
    
    private func rawContentByHtmlString(htmlString: NSString) -> NSString {
        var match: RxMatch = htmlString.firstMatchWithDetails(NSRegularExpression(pattern: "<textarea.*?>(.*?)</textarea>",
                                                    options: NSRegularExpressionOptions.DotMatchesLineSeparators,
                                                    error: nil))
        var rawEncodedContent: NSString = (match.groups[1] as RxMatchGroup).value()
        return rawEncodedContent.stringByDecodingHTMLEntities()
    }
    
    private func sourceTypeByHtmlString(htmlString: NSString) -> Int {
        return htmlString.firstMatch(NSRegularExpression(pattern: "(?<=type:')\\d(?=')")).toInt()!
    }
    
    private func categoriesByHtmlString(htmlString: NSString) -> NSString {
        return htmlString.firstMatch(NSRegularExpression(pattern: "(?<=tags:').*?(?=')"))
    }
    
    private func tagsByHtmlString(htmlString: NSString) -> NSString {
        return htmlString.firstMatch(NSRegularExpression(pattern: "(?<=tag2:').*?(?=')"))
    }
    
    private func errorMessageForHtmlString(htmlString: NSString) -> NSString? {
        var errorMessage : NSString? = htmlString.firstMatch(NSRegularExpression(pattern: "Service Temporarily Unavailable"))
        return errorMessage
    }
    
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!, error: NSErrorPointer) -> AnyObject! {
        var htmlString: NSString? = NSString(data: data, encoding: NSUTF8StringEncoding)
        var errorMessage: NSString? = errorMessageForHtmlString(htmlString!)

        if htmlString != nil && (errorMessage == nil || errorMessage?.isEqualToString("") == true) {
            var articleID = response.URL.lastPathComponent
            var article: CSDNArticle = self.articlesSummary.filter({(includeElement: CSDNArticle!) in
                return includeElement.articleID!.isEqualToString(articleID)
                })[0] as CSDNArticle
            
            article.rawContent = rawContentByHtmlString(htmlString!)
            
            var jsonString = htmlString!.firstMatch(NSRegularExpression(pattern: "(?<=jsonData=)\\{.*?\\}",
                                                                options: NSRegularExpressionOptions.DotMatchesLineSeparators,
                                                                error: nil))
                                .stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
            article.sourceType = ArticleSourceType.fromRaw(sourceTypeByHtmlString(jsonString!))!
            article.categories = categoriesByHtmlString(jsonString!)
            article.tags = tagsByHtmlString(jsonString!)
            return article;
        } else {
            error.memory = NSError(domain: "CSDN", code: 998, userInfo: ["errorMessage" : errorMessage!])
            return nil
        }
    }
}
