//
//  Project-Bridging-Header.h
//  CSDNBlogExporter-Swift
//
//  Created by ZhangAo on 14-7-21.
//  Copyright (c) 2014年 ZA. All rights reserved.
//

#import "AFNetworking.h"
#import "RegExCategories.h"
#import "NSString+HTML.h"

typedef void(^requestSuccessBlock)(id object,BOOL isBatchCompleted);
typedef void(^requestFailedBlock)(NSError *error);