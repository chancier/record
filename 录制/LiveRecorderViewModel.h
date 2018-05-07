//
//  LiveRecorderViewModel.h
//  LiaoBa
//
//  Created by lixf on 17/3/10.
//  Copyright © 2017年 User. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveBaseViewController.h"

@interface LiveRecorderViewModel : NSObject

@property(nonatomic,weak)LiveBaseViewController *conentVC;

@property(nonatomic,strong)UIView *view;

@property(nonatomic,strong)void (^cancelAction)();
@property(nonatomic,strong)void (^compeleAction)(BOOL finished);

-(void)initUI;

-(void)recordViewShow;

-(void)recordViewHide;

-(void)startRecorder;

-(void)stopRecorder;

-(void)destroy;

@end
