//
//  VideoMaker.m
//  VideoMaker
//
//  Created by apple on 2017/10/17.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "VideoMaker.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
@implementation VideoMaker

+(id)shareInstance{
    static VideoMaker *maker = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        maker = [[self alloc]init];
    });
    
    return maker;
}
/**
 *  裁剪图片
 *
 *  @param image  图片
 *  @param bounds 大小
 *
 */
+ (UIImage *)croppedImage:(UIImage *)image bounds:(CGRect)bounds
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], bounds);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return croppedImage;
}

+ (UIImage *)clipImage:(UIImage *)image ScaleWithsize:(CGSize)asize
{
    UIImage *newimage;
    if (nil == image) {
        newimage = nil;
    }
    else{
        CGSize oldsize = image.size;
        CGRect rect;
        if (asize.width/asize.height > oldsize.width/oldsize.height) {
            rect.size.width = asize.width;
            rect.size.height = asize.width*oldsize.height/oldsize.width;
            rect.origin.x = 0;
            rect.origin.y = (asize.height - rect.size.height)/2;
        }
        else{
            rect.size.width = asize.height*oldsize.width/oldsize.height;
            rect.size.height = asize.height;
            rect.origin.x = (asize.width - rect.size.width)/2;
            rect.origin.y = 0;
        }
        UIGraphicsBeginImageContext(asize);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextClipToRect(context, CGRectMake(0, 0, asize.width, asize.height));
        CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
        UIRectFill(CGRectMake(0, 0, asize.width, asize.height));//clear background
        [image drawInRect:rect];
        newimage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return newimage;
}

+ (CVPixelBufferRef )pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options, &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4*size.width, rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);
    //CGSize drawSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    //BOOL baseW = drawSize.width < drawSize.height;
    
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

/**
 *  多张图片合成视频
 *
 */
- (void)compressImages:(NSArray *)images completion:(void(^)(NSURL *outurl))block;
{
    
    //先裁剪图片
    NSMutableArray *imageArray = [NSMutableArray array];
    for (UIImage *image in images)
    {
        CGRect rect = CGRectMake(0, 0,image.size.width, image.size.height);
        if (rect.size.width < rect.size.height)
        {
            rect.origin.y = (rect.size.height - rect.size.width)/2;
            rect.size.height = rect.size.width;
        }else
        {
            rect.origin.x = (rect.size.width - rect.size.height)/2;
            rect.size.width = rect.size.height;
        }
        //裁剪
        UIImage *newImage = [VideoMaker croppedImage:image bounds:rect];
        /**
         *  缩放
         */
        UIImage *finalImage = [VideoMaker clipImage:newImage ScaleWithsize:CGSizeMake(640, 960)];
        [imageArray addObject:finalImage];
    }
    
    NSDate *date = [NSDate date];
    NSString *string = [NSString stringWithFormat:@"%ld.mov",(unsigned long)(date.timeIntervalSince1970 * 1000)];
    NSString *cachePath = [NSTemporaryDirectory() stringByAppendingPathComponent:string];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
    }
    NSURL    *exportUrl = [NSURL fileURLWithPath:cachePath];
    CGSize size = CGSizeMake(640,640);//定义视频的大小
    __block AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:exportUrl
                                                                   fileType:AVFileTypeQuickTimeMovie
                                                                      error:nil];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    
    if ([videoWriter canAddInput:writerInput])
        NSLog(@"");
    else
        NSLog(@"");
    
    [videoWriter addInput:writerInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //合成多张图片为一个视频文件
    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    int __block frame = 0;
    __weak typeof(self) ws = self;
    
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        while ([writerInput isReadyForMoreMediaData])
        {
            if(++frame > 8 * 30)
            {
                [writerInput markAsFinished];
                //[videoWriter_ finishWriting];
                if(videoWriter.status == AVAssetWriterStatusWriting){
                    NSCondition *cond = [[NSCondition alloc] init];
                    [cond lock];
                    [videoWriter finishWritingWithCompletionHandler:^{
                        [cond lock];
                        [cond signal];
                        [cond unlock];
                    }];
                    [cond wait];
                    [cond unlock];
                    !block?:block(exportUrl);
                }
                break;
            }
            CVPixelBufferRef buffer = NULL;
            
            int idx = frame/30 * images.count/8;
            if (idx >= images.count) {
                idx = images.count - 1;
            }
            buffer = (CVPixelBufferRef)[VideoMaker pixelBufferFromCGImage:[[imageArray objectAtIndex:idx] CGImage] size:size];
            if (buffer)
            {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, 60)])
                {
                    NSLog(@"fail");
                }else
                {
                    NSLog(@"success:%ld",frame);
                }
                CFRelease(buffer);
            }
        }
    }];
    
}

@end
