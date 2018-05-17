//
//  ControlsView.h
//  KTPlay
//
//  Created by Ki on 2018/5/16.
//  Copyright © 2018年 Ki. All rights reserved.
//

#import <UIKit/UIKit.h>
@class KTSlider;

@protocol ControllersViewDelegate<NSObject>
@required
/**
 播放按钮点击事件
 @param selected 按钮选中状态
 */
- (void)playButtonAction:(BOOL)selected;
/** 全屏切换按钮点击事件 */
- (void)fullScreenButtonAction;
- (void)retryButtonAction;

/** 滑杆开始拖动 */
- (void)videoSliderDragBegan:(KTSlider *)slider;
/** 滑杆拖动中 */
- (void)videoSliderDragingValueChanged:(KTSlider *)slider;
/** 滑杆结束拖动 */
- (void)videoSliderDraged:(KTSlider *)slider;


@optional
/** 控制面板单击事件 */
- (void)tapControllersViewGesture;
/** 控制面板双击事件 */
- (void)doubleTapControllersViewGesture;

@end


@interface ControlsView : UIView

@property (nonatomic,weak)id <ControllersViewDelegate> delegate;

@property (nonatomic,assign)CGFloat progressValue;

/**
 设置视频时间显示以及滑杆状态
 @param playTime 当前播放时间
 @param totalTime 视频总时间
 @param sliderValue 滑杆滑动值
 */
- (void)_setPlaybackControlsWithPlayTime:(NSInteger)playTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)sliderValue;

- (void)playerStatus:(BOOL)isPlay;



@end




