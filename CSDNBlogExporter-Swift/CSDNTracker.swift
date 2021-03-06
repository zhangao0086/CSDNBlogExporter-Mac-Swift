//
//  CSDNTracker.swift
//  CSDNBlogExporter-Swift
//
//  Created by ZhangAo on 14-7-21.
//  Copyright (c) 2014年 ZA. All rights reserved.
//

import Cocoa

func errorMessageInError(error: NSError) -> NSString {
    return error.userInfo["errorMessage"] as! NSString
}

class CSDNTracker: AFHTTPResponseSerializer {
    private let manager = AFHTTPSessionManager()
    
    var isGet : Bool = true
    var requestURLString : NSString = ""
    var isBatchRequests : Bool = false
    var requestURLStrings : Array<String>?
    var postParams : NSDictionary?
    
    func sendRequest(successBlock: requestSuccessBlock,failedBlock: requestFailedBlock){
        dispatch_async(dispatch_get_global_queue(0, 0), {
            if self.isBatchRequests {
                self.sendMultiRequest(successBlock, failedBlock: failedBlock)
            } else {
                self.sendSingleRequest(successBlock, failedBlock: failedBlock)
            }
        })
    }
    
    private func sendMultiRequest(successBlock: requestSuccessBlock, failedBlock: requestFailedBlock) {
		self.manager.responseSerializer = self;
		let group = dispatch_group_create()
		var i: Int = 0
		for urlString: String in self.requestURLStrings! {
			dispatch_group_enter(group)
			let delayInSeconds: Int64 = 1
			let delay = Double(Double(delayInSeconds) * Double(i) * Double(NSEC_PER_SEC))
			let popTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, (Int64)(delay))
			dispatch_after(popTime, dispatch_get_main_queue(), {
				self.manager.GET(
					urlString,
					parameters: nil,
					progress: nil,
					success: { task, responseObject in
						dispatch_group_leave(group)
						successBlock(responseObject, false)
					},
					failure: { task, error in
						dispatch_group_leave(group)
						failedBlock(error)
				})
			})
			i++
		}
		dispatch_group_notify(group, dispatch_get_main_queue(), {
			successBlock(nil,true)
		})
	}
	
	private func sendSingleRequest(successBlock: requestSuccessBlock, failedBlock: requestFailedBlock) {
		self.manager.responseSerializer = self
		if self.isGet {
			self.manager.GET(
				self.requestURLString as String,
				parameters: nil,
				progress: nil,
				success: { task, responseObject in
					dispatch_async(dispatch_get_main_queue(), {
						successBlock(responseObject,true)
					})
				},
				failure: { task, error in
					dispatch_async(dispatch_get_main_queue(), {
						failedBlock(error)
					})
			})
		} else {
			self.manager.POST(
				self.requestURLString as String,
				parameters: self.postParams,
				progress: nil,
				success: { task, responseObject in
					dispatch_async(dispatch_get_main_queue(), {
						successBlock(responseObject,true)
					})
				},
				failure: { task, error in
					dispatch_async(dispatch_get_main_queue(), {
						failedBlock(error)
					})
			})
		}
	}
}
