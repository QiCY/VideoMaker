//
//  VideoMaker.h
//  VideoMaker
//
//  Created by apple on 2017/10/17.
//  Copyright © 2017年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoMaker : NSObject
+(id)shareInstance;
- (void)compressImages:(NSArray *)images completion:(void(^)(NSURL *outurl))block;
@end
