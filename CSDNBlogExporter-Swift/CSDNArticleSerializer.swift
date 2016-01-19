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
                urlStrings[i++] = "http://write.blog.csdn.net/postedit/" + (articleSummary.articleID! as String)
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

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func rawContentByHtmlString(htmlString: NSString) -> NSString {
        let match: RxMatch = htmlString.firstMatchWithDetails(try? NSRegularExpression(pattern: "<textarea.*?>(.*?)</textarea>",
                                                    options: NSRegularExpressionOptions.DotMatchesLineSeparators))
        let rawEncodedContent: NSString = (match.groups[1] as! RxMatchGroup).value
        return rawEncodedContent.stringByDecodingHTMLEntities()
    }
    
    private func sourceTypeByHtmlString(htmlString: NSString) -> Int {
        return Int(htmlString.firstMatch(NSRegularExpression(pattern: "(?<=type:')\\d(?=')")))!
    }
    
    private func categoriesByHtmlString(htmlString: NSString) -> NSString {
        return htmlString.firstMatch(NSRegularExpression(pattern: "(?<=tags:').*?(?=')"))
    }
    
    private func tagsByHtmlString(htmlString: NSString) -> NSString {
        return htmlString.firstMatch(NSRegularExpression(pattern: "(?<=tag2:').*?(?=')"))
    }
    
    private func errorMessageForHtmlString(htmlString: NSString) -> NSString? {
        let errorMessage : NSString? = htmlString.firstMatch(NSRegularExpression(pattern: "Service Temporarily Unavailable"))
		return errorMessage
	}
	
	override func responseObjectForResponse(response: NSURLResponse?, data: NSData?, error: NSErrorPointer) -> AnyObject? {
		if let data = data, let htmlString = NSString(data: data, encoding: NSUTF8StringEncoding) {
			let errorMessage: NSString? = errorMessageForHtmlString(htmlString)
			
			if (errorMessage == nil || errorMessage?.isEqualToString("") == true) {
				let articleID = response!.URL!.fragment?.componentsSeparatedByString("=").last
				let article: CSDNArticle = self.articlesSummary.filter({(includeElement: CSDNArticle!) in
					return includeElement.articleID!.isEqualToString(articleID!)
				}).first!
				
				article.rawContent = rawContentByHtmlString(htmlString)
				
				let jsonString = htmlString.firstMatch(try? NSRegularExpression(pattern: "(?<=jsonData=)\\{.*?\\}",
					options: NSRegularExpressionOptions.DotMatchesLineSeparators))
					.stringByRemovingPercentEncoding
				article.sourceType = ArticleSourceType(rawValue: sourceTypeByHtmlString(jsonString!))!
				article.categories = categoriesByHtmlString(jsonString!)
				article.tags = tagsByHtmlString(jsonString!)
				return article;
			}
		}
		return nil
	}
	
}
