//
//  CSDNArticle.swift
//  CSDNBlogExporter-Swift
//
//  Created by ZhangAo on 14-7-22.
//  Copyright (c) 2014年 ZA. All rights reserved.
//

import Cocoa

enum ArticleSourceType: Int {
    case ArticleSourceTypeOriginal = 1
    case ArticleSourceTypeReprint = 2
    case ArticleSourceTypeTranslate = 4
}

class CSDNArticle: NSObject {

    var articleID: NSString?
    var articleTitle: NSString?
    var rawContent: NSString?
    var publishTime: NSString?
    var categories: NSString?
    var tags: NSString?
    
    var sourceType: ArticleSourceType = ArticleSourceType.ArticleSourceTypeOriginal
}
