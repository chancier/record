//
//  LiveRecorderViewModel.m
//  LiaoBa
//
//  Created by lixf on 17/3/10.
//  Copyright © 2017年 User. All rights reserved.
//

#import "LiveRecorderViewModel.h"
#import "ASScreenRecorder.h"
#import "BlazeiceAudioRecordAndTransCoding.h"
#import "WFCaptureUtilities.h"
#import "LiveVideoShareViewModel.h"
#import "UIImage+Alpha.h"
#import <Photos/Photos.h>
#import "ZZCircleProgress.h"
#import "ZZCACircleProgress.h"

#define VEDIOPATH @"vedioPath"

@interface LiveRecorderViewModel()

@property(nonatomic,strong)LiveVideoShareViewModel *videoShareVM;
@property(nonatomic,strong)UIImage *fristImage;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *progress_con;
@property(strong, nonatomic)NSTimer *recordTimer;
@property(nonatomic,assign)BOOL isRecord;
@property(nonatomic,assign)BOOL isExit;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIView *lineView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pointView_con;
@property (weak, nonatomic) IBOutlet ZZCircleProgress *progressView;
@property (weak, nonatomic) IBOutlet UIButton *operateBtn;
@property (weak, nonatomic) IBOutlet UIButton *showGiftBtn;
@property (weak, nonatomic) IBOutlet UILabel *timeLab;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *circleWithConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *circleBottomConstraint;


@property(nonatomic,strong)UIView *bgView;
@property(nonatomic,assign)BOOL isCancel;
@end

@interface LiveRecorderViewModel()<AVAudioRecorderDelegate,BlazeiceAudioRecordAndTransCodingDelegate>
{
    //BOOL isRecing;//正在录制中
    //BOOL isPauseing;//正在暂停中
    BlazeiceAudioRecordAndTransCoding *audioRecord;
    NSString* opPath;
    NSString* mergedPath;
    CGFloat progressNum;
}
@end

@implementation LiveRecorderViewModel


-(void)initUI
{
    self.bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, UI_SCREEN_WIDTH, ScreenHeight-180)];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hidemyself)];
    [self.bgView addGestureRecognizer:tap];
    self.bgView.hidden = YES;
    [self.conentVC.view.window addSubview:self.bgView];
    
    self.view = [[[NSBundle mainBundle]loadNibNamed:@"LiveToolBarRecordView" owner:self options:nil] lastObject];
    self.view.frame = CGRectMake(0, UI_SCREEN_HEIGHT, UI_SCREEN_WIDTH, 180);
//    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    
    [self.conentVC.view.window addSubview:self.view];
    
    UIView *maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UI_SCREEN_WIDTH, 180)];
    UIColor *colorOne = [UIColor colorWithRed:(0/255.0)  green:(0/255.0)  blue:(0/255.0)  alpha:0.0];
    UIColor *colorTwo = [UIColor colorWithRed:(0/255.0)  green:(0/255.0)  blue:(0/255.0)  alpha:0.6];
    NSArray *colors = [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor, nil];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(0, 1);
    gradient.colors = colors;
    gradient.frame = CGRectMake(0, 0, UI_SCREEN_WIDTH, 180);
    [maskView.layer insertSublayer:gradient atIndex:0];
    [self.view addSubview:maskView];
    [self.view sendSubviewToBack:maskView];
    
    self.recordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(recordTimerAction) userInfo:nil repeats:YES];
    [self.recordTimer setFireDate:[NSDate distantFuture]];
    self.isRecord = NO;
    self.isExit = NO;
    
    self.recordButton.layer.cornerRadius = 18;
    self.recordButton.layer.borderWidth = 1;
    self.recordButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.recordButton setTitle:@"松手完成" forState:UIControlStateHighlighted];
    [self.recordButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    [self.recordButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.pointView_con.constant = UI_SCREEN_WIDTH/30;
    self.lineView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    
    self.operateBtn.layer.cornerRadius = 65.0/2.0;
    self.operateBtn.layer.masksToBounds = YES;
    
    
    _progressView.duration = 2;
    _progressView.notAnimated = YES;
    _progressView.showPoint = NO;
    _progressView.showProgressText = NO;
    _progressView.strokeWidth = 5.0f;
    _progressView.animationModel = CircleIncreaseSameTime;
    _progressView.pathBackColor = [UIColor whiteColor];
    _progressView.pathFillColor = RGB(150, 86, 255);
    
    self.showGiftBtn.selected = YES;
    
}

-(void)hidemyself{
    [self cancelOperation];
}

- (IBAction)cancelAction:(id)sender {
    self.isCancel = YES;
    [self cancelOperation];
}

-(void)cancelOperation{
    
    [self endState];
    [self stopRecorder];
    if (self.cancelAction) {
        self.cancelAction();
    }
}

-(void)endState{
    
    progressNum = 0.0f;
    self.showGiftBtn.selected = YES;
    self.showGiftBtn.enabled = YES;
    self.showGiftBtn.alpha = 1.0;
    self.isRecord = NO;
    self.progress_con.constant = 0;
    self.timeLab.text = @"点击录制";
    self.progressView.progress =0.0f;
    [self.recordTimer setFireDate:[NSDate distantFuture]];
    self.operateBtn.selected = NO;
    self.operateBtn.backgroundColor = [UIColor clearColor];
    self.circleWithConstraint.constant = 77.0f;
    self.circleBottomConstraint.constant = 20.0f;
}

- (IBAction)recordAction:(id)sender {
    self.isRecord = YES;
    self.recordButton.layer.borderColor = [[UIColor whiteColor]colorWithAlphaComponent:0.5].CGColor;
    [self.recordTimer setFireDate:[NSDate date]];
    [self startRecorder];
}

- (IBAction)showGiftAction:(UIButton*)sender {
    sender.selected = !sender.selected;
    BOOL select = sender.selected;
    if (select) {
        [sender setTitle:@"显示礼物" forState:UIControlStateNormal];
    }else{
        [sender setTitle:@"隐藏礼物" forState:UIControlStateNormal];
    }
    self.conentVC.animView.hidden = select;
    //不管显示不显示礼物，都隐藏掉入场效果
    [[NSNotificationCenter defaultCenter]postNotificationName:@"LiveEnterVehicleAnimOperation" object:@0];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"LiveEnterAnimOperation" object:@0];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"LiveAnimOperationManager" object:@0];
}

- (IBAction)newStartAction:(UIButton*)sender {
    
    sender.selected = !sender.selected;
    
    
    if (sender.selected) {
        sender.backgroundColor = RGB(150, 86, 255);
        [self.recordTimer setFireDate:[NSDate date]];
        [self startRecorder];
        self.showGiftBtn.enabled = NO;
        self.showGiftBtn.alpha = 0.5;
        self.circleWithConstraint.constant = 87.0f;
        self.circleBottomConstraint.constant = 15.0f;
    }else{
        sender.backgroundColor = [UIColor clearColor];
        [self recordCancelAction:nil];
        self.showGiftBtn.enabled = YES;
        self.showGiftBtn.alpha = 1.0;
        self.circleWithConstraint.constant = 77.0f;
        self.circleBottomConstraint.constant = 20.0f;
        
    }
    self.isRecord = sender.selected;
}

- (IBAction)recordCancelAction:(id)sender {
    //NSLog(@"recordCancelAction");
    self.recordButton.layer.borderColor = [UIColor whiteColor].CGColor;
    if (self.isRecord == YES) {
        self.isRecord = NO;
        [self.recordTimer setFireDate:[NSDate distantFuture]];
        [SVProgressHUD showWithStatus:@"录屏处理中"];
        [self stopRecorder];
    }
}




-(void)recordViewShow
{
    self.isCancel = NO;
    self.conentVC.isScreencap = YES;
    self.conentVC.animView.hidden = self.showGiftBtn.selected;
    [[NSNotificationCenter defaultCenter]postNotificationName:@"HandleLiveBarrageManagerShow" object:@0];//隐藏弹幕
    
    self.bgView.hidden = NO;
    BOOL select = self.showGiftBtn.selected;
    if (select) {
        [self.showGiftBtn setTitle:@"显示礼物" forState:UIControlStateNormal];
    }else{
        [self.showGiftBtn setTitle:@"隐藏礼物" forState:UIControlStateNormal];
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame = CGRectMake(0, UI_SCREEN_HEIGHT - 180, UI_SCREEN_WIDTH, 180);
    }];
}

-(void)recordViewHide
{
    self.conentVC.isScreencap = NO;
    self.bgView.hidden = YES;
    self.conentVC.baseView.userInteractionEnabled = YES;
    progressNum = 0.0f;
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"HandleLiveBarrageManagerShow" object:@1];//显示弹幕
    [[NSNotificationCenter defaultCenter]postNotificationName:@"LiveEnterVehicleAnimOperation" object:@1];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"LiveEnterAnimOperation" object:@1];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"LiveAnimOperationManager" object:@1];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame = CGRectMake(0, UI_SCREEN_HEIGHT, UI_SCREEN_WIDTH, 180);
        self.conentVC.animView.hidden = NO;
        
        [self.conentVC reloadFocusView];
    }];
}

-(void)startRecorder
{
    self.bgView.hidden = YES;
    self.conentVC.baseView.userInteractionEnabled = NO;
    progressNum = 0.0;
    self.fristImage = [UIImage snapshot:self.view.window];
    ASScreenRecorder* screenRecorder = [ASScreenRecorder sharedInstance];
    screenRecorder.recordView = self.conentVC.view;
    [screenRecorder startRecording];
    [self startAudioRecord];
}

-(void)stopRecorder
{
    self.progress_con.constant = 0;
    self.timeLab.text = @"点击录制";
    self.progressView.progress =0.0f;
    self.conentVC.baseView.userInteractionEnabled = YES;
    self.operateBtn.selected = NO;
    self.operateBtn.backgroundColor = [UIColor clearColor];
    self.circleWithConstraint.constant = 77.0f;
    self.circleBottomConstraint.constant = 20.0f;
    
    ASScreenRecorder* screenRecorder = [ASScreenRecorder sharedInstance];
    [screenRecorder stopRecordingWithCompletion:^(NSString *outputVideoPath) {
        NSLog(@"stopRecorder %@",outputVideoPath);
        opPath=outputVideoPath;
        
        if (audioRecord) {
            [audioRecord endRecord];
        }
//        [self endVedio];
    }];
    
}

-(void)recordTimerAction
{
    progressNum += 1.0;
    self.progress_con.constant = progressNum/60.0f * UI_SCREEN_WIDTH;
    
    //自动结束
    if (progressNum > 60) {
        [self recordCancelAction:nil];
        return;
    }
    
    self.progressView.progress = progressNum/60.0f;
    self.timeLab.text = [NSString stringWithFormat:@"%.0f秒",progressNum];
}



-(void)videoShareView
{
    [self endState];
    //出现分享，隐藏录音控件
    if (self.cancelAction) {
        self.cancelAction();
    }
    WeakSelf(self);
    [self.videoShareVM initUI];
    [self.videoShareVM showShareText:@"" image:self.fristImage file:mergedPath];
    self.videoShareVM.cancelAction = ^{
        [weakself videoShareViewHide];
    };
    self.videoShareVM.reRecordAction = ^{
        [weakself videoShareViewHide];
        if (weakself.conentVC.toolBarViewModel.view.recordAction) {
            weakself.conentVC.toolBarViewModel.view.recordAction();
        }
    };
    
    self.videoShareVM.clickAction = ^{//是否点了第三方分享图标隐藏看需求，暂时注释
//        [weakself videoShareViewHide];
        
    };
    
}

-(void)videoShareViewHide
{
    [self.videoShareVM hide];
    self.videoShareVM = nil;
}

- (NSString*)getPathByFileName:(NSString *)_fileName ofType:(NSString *)_type
{
    NSString* fileDirectory = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:_fileName]stringByAppendingPathExtension:_type];
    return fileDirectory;
}

-(void)startAudioRecord
{
    if (!audioRecord) {
        audioRecord = [[BlazeiceAudioRecordAndTransCoding alloc]init];
        audioRecord.recorder.delegate=self;
        audioRecord.delegate=self;
    }
    NSString* path=[self getPathByFileName:VEDIOPATH ofType:@"wav"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]){
        [fileManager removeItemAtPath:path error:nil];
    }
    [self performSelector:@selector(toStartAudioRecord) withObject:nil afterDelay:0.1];
}

#pragma mark -
#pragma mark audioRecordDelegate
/**
 *  开始录音
 */
-(void)toStartAudioRecord
{
    [audioRecord beginRecordByFileName:VEDIOPATH];
}
/**
 *  音频录制结束合成视频音频
 */
-(void)wavComplete
{
    //视频录制结束,为视频加上音乐
    if (audioRecord && progressNum>=2.0 && !_isExit) {
        NSString* path=[self getPathByFileName:VEDIOPATH ofType:@"wav"];
        [WFCaptureUtilities mergeVideo:opPath andAudio:path andTarget:self andAction:@selector(mergedidFinish:WithError:)];
    }
    else if (progressNum<2.0)
    {//要区分 点“取消”导致的
        if (!self.isCancel) {
            [SVProgressHUD showErrorWithStatus:@"最少录制2秒短视频"];
        }
        
    }
}

-(void)endVedio
{
    //视频录制结束
    if (progressNum>=2.0 && !_isExit) {
        [self mergedidFinish:opPath WithError:nil];
    }
    else if (progressNum<2.0)
    {//要区分 点“取消”导致的
        if (!self.isCancel) {
            [SVProgressHUD showErrorWithStatus:@"最少录制2秒短视频"];
        }
        
    }
}


- (BOOL)isCanUsePhotos {
    
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
//        ALAuthorizationStatus author =[ALAssetsLibrary authorizationStatus];
//        if (author == kCLAuthorizationStatusRestricted || author == kCLAuthorizationStatusDenied) {
//            //无权限
//            return NO;
//        }
//    }
//    else {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusAuthorized ) {
            //有权限
            return YES;
        }
//    }
    return NO;
}

- (void)mergedidFinish:(NSString *)videoPath WithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        
    });
    
    [MSDeviceAuthority requestPhotoAuthorization:^ {
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:videoPath]
                                    completionBlock:^(NSURL *assetURL, NSError *error) {
                                        if (error) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                
                                                [SVProgressHUD showImage:nil status:@"保存至手机相册失败" duration:2];
                                                if (self.compeleAction) {
                                                    self.compeleAction(NO);
                                                }
                                            });
                                        } else {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                
                                                [SVProgressHUD showImage:nil status:@"视频已保存至手机相册" duration:2];
                                                if (self.compeleAction) {
                                                    self.compeleAction(YES);
                                                }
                                            });
                                        }
                                    }];
        mergedPath = videoPath;
        [self performSelectorOnMainThread:@selector(videoShareView) withObject:nil waitUntilDone:YES];

    }];
    
    
}


-(void)destroy
{
    self.isExit = YES;
    [self.view removeFromSuperview];
    [self.recordTimer invalidate];
    [self stopRecorder];
}

-(void)dealloc
{
    NSLog(@"LiveRecorderViewModel dealloc");
}


- (LiveVideoShareViewModel *)videoShareVM
{
    if (!_videoShareVM) {
        _videoShareVM = [[LiveVideoShareViewModel alloc]init];
        _videoShareVM.conentVC = self.conentVC;
    }
    return _videoShareVM;
}

@end
