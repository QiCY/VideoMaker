//
//  ViewController.m
//  VideoMaker
//
//  Created by apple on 2017/10/17.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "VideoMaker.h"
#import <AFNetworking.h>
#import<AssetsLibrary/AssetsLibrary.h>
@interface ViewController ()
@property(nonatomic,strong)NSURL *theVideoPath;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton * button =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:CGRectMake(100,100, 100,50)];
    [button setTitle:@"视频合成"forState:UIControlStateNormal];
    [button addTarget:self action:@selector(beginMakeVideo)forControlEvents:UIControlEventTouchUpInside];
    button.backgroundColor = [UIColor redColor];
    [self.view addSubview:button];
    
    UIButton * button1 =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button1 setFrame:CGRectMake(100,200, 100,50)];
    [button1 setTitle:@"视频播放"forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(playAction)forControlEvents:UIControlEventTouchUpInside];
    button1.backgroundColor = [UIColor redColor];
    [self.view addSubview:button1];
    
    
    
}
-(void)saveVideoToLibary:(NSURL *)url{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:url
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    if (error) {
                                        NSLog(@"Save video fail:%@",error);
                                    } else {
                                        NSLog(@"Save video succeed.");
                                    }
                                }];
}
-(void)beginMakeVideo{
    NSMutableArray *array = [NSMutableArray array];
    for (int i =1 ; i<7; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg",i]];
        [array addObject:image];
    }
    __weak typeof(self) weakSelf = self;
    [[VideoMaker shareInstance] compressImages:array completion:^(NSURL *outurl) {
        _theVideoPath = outurl;
        [weakSelf saveVideoToLibary:outurl];
    }];
}
//播放
-(void)playAction
{
    NSLog(@"************%@",self.theVideoPath.absoluteString);
    NSURL *sourceMovieURL = self.theVideoPath;
    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame =CGRectMake(0, self.view.frame.size.height - 240, self.view.frame.size.width, 240);
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    [player play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
