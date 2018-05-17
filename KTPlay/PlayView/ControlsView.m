//
//  ControlsView.m
//  KTPlay
//
//  Created by Ki on 2018/5/16.
//  Copyright © 2018年 Ki. All rights reserved.
//

#import "ControlsView.h"
#import "KTSlider.h"
#import <Masonry.h>

@interface ControlsView ()

@property (nonatomic,strong)UIView * bottomControllersView;
@property (nonatomic,strong)KTSlider * slider;
@property (nonatomic,strong)UIButton * playBtn;
@property (nonatomic,strong)UILabel * startTimeLab;
@property (nonatomic,strong)UILabel * totalTimeLab;
@property (nonatomic,strong)UIButton * fullScreenBtn;
/** 进度条 */
@property (nonatomic, strong) UIProgressView *progress;
@end

@implementation ControlsView

#pragma mark - set
- (void)setProgressValue:(CGFloat)progressValue{
    _progressValue = progressValue;
    
    [self.progress setProgress:progressValue];
}

/**
 设置视频时间显示以及滑杆状态
 @param playTime 当前播放时间
 @param totalTime 视频总时间
 @param sliderValue 滑杆滑动值
 */
- (void)_setPlaybackControlsWithPlayTime:(NSInteger)playTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)sliderValue{
    //当前时长进度progress
    NSInteger proMin = playTime / 60;//当前秒
    NSInteger proSec = playTime % 60;//当前分钟
    //duration 总时长
    NSInteger durMin = totalTime / 60;//总秒
    NSInteger durSec = totalTime % 60;//总分钟
    
    //更新当前播放时间
    self.slider.value = sliderValue;
    self.startTimeLab.text = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    //更新总时间
    self.totalTimeLab.text = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
}

- (void)playerStatus:(BOOL)isPlay{
    if (isPlay) {
        self.playBtn.selected = YES;
    }else{
        self.playBtn.selected = NO;
    }
}

#pragma mark - 初始化
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - 创建UI
- (void)setupUI{
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.bottomControllersView];
    [self addSubview:self.playBtn];

    [self makeConstraints];
    [self addGesture];
}

#pragma mark - 添加约束
- (void)makeConstraints{
    
    __weak typeof(self) weakSelf = self;
    
    [_playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(80, 80));
    }];
    
    [_bottomControllersView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@30);
    }];

    [_fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.equalTo(weakSelf.bottomControllersView);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];

    [_startTimeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(weakSelf.bottomControllersView).offset(5);
        make.width.equalTo(@45);
        make.centerY.equalTo(weakSelf.bottomControllersView.mas_centerY);
    }];

    [_totalTimeLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(weakSelf.fullScreenBtn.mas_left).offset(-5);
        make.width.equalTo(@45);
        make.centerY.equalTo(weakSelf.bottomControllersView.mas_centerY);
    }];
    
    [_progress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(weakSelf.startTimeLab.mas_right).offset(5);
        make.right.equalTo(weakSelf.totalTimeLab.mas_left).offset(-5);
        make.height.equalTo(@2);
        make.centerY.equalTo(weakSelf.bottomControllersView.mas_centerY);
    }];

    
    [_slider mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.equalTo(weakSelf.progress);
        make.left.equalTo(weakSelf.progress.mas_left);
        make.right.equalTo(weakSelf.progress.mas_right);
        make.height.equalTo(@2);
        make.centerY.equalTo(weakSelf.progress.mas_centerY).offset(-1);
    }];
    
}

#pragma mark - 添加手势
- (void)addGesture{
    //单击手势
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:singleTapGesture];
    
    //双击手势
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTapGesture];
    
    //当系统检测不到双击手势时执行再识别单击手势，解决单双击收拾冲突
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
}

#pragma mark - LazyingLoad
/** 滑杆 */
- (KTSlider *)slider{
    if (!_slider) {
        KTSlider * slider = [[KTSlider alloc]init];
        slider.maximumTrackTintColor = [UIColor clearColor];
       // [slider setThumbTintColor:[UIColor greenColor]];
        [slider setMinimumTrackTintColor:[UIColor lightGrayColor]];
        //开始拖动事件
        [slider addTarget:self action:@selector(videoSliderDragBegan:) forControlEvents:UIControlEventTouchDown];
        //拖动中事件
        [slider addTarget:self action:@selector(videoSliderDragingValueChanged:) forControlEvents:UIControlEventValueChanged];
        //结束拖动事件
        [slider addTarget:self action:@selector(videoSliderDraged:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
        _slider = slider;
    }
    return _slider;
}

/** 底部控制栏 */
- (UIView *)bottomControllersView{
    if (!_bottomControllersView) {
        UIView * bottomView  = [[UIView alloc]init];
        bottomView.backgroundColor = UIColor.purpleColor;
        bottomView.userInteractionEnabled = YES;
        [bottomView addSubview:self.fullScreenBtn];
        [bottomView addSubview:self.startTimeLab];
        [bottomView addSubview:self.progress];
        [bottomView addSubview:self.slider];
        [bottomView addSubview:self.totalTimeLab];
        _bottomControllersView = bottomView;
    }
    return _bottomControllersView;
}

/** 播放按钮 */
- (UIButton *)playBtn{
    if (!_playBtn){
        UIButton * pBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [pBtn setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
        [pBtn setImage:[UIImage imageNamed:@"btn_play"] forState:UIControlStateSelected];
        [pBtn addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
        _playBtn = pBtn;
    }
    return _playBtn;
}

/** 全屏切换按钮 */
-(UIButton *)fullScreenBtn{
    if (!_fullScreenBtn) {
        UIButton * fBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [fBtn setImage:[UIImage imageNamed:@"ic_turn_screen_white_18x18_"] forState:UIControlStateNormal];
        [fBtn setImage:[UIImage imageNamed:@"ic_zoomout_screen_white_18x18_"] forState:UIControlStateSelected];
        // [fBtn addTarget:self action:@selector(fullScreenAction) forControlEvents:UIControlEventTouchUpInside];
        _fullScreenBtn = fBtn;
    }
    return _fullScreenBtn;
}


/** 当前播放时间 */
- (UILabel *)startTimeLab{
    if (!_startTimeLab) {
        UILabel * starLab = [[UILabel alloc]init];
        starLab.font = [UIFont systemFontOfSize:14];
        starLab.text = @"00:00";
        starLab.adjustsFontSizeToFitWidth = YES;
        starLab.textAlignment = NSTextAlignmentCenter;
        starLab.textColor = [UIColor whiteColor];
        _startTimeLab = starLab;
    }
    return _startTimeLab;
}

/** 视频总时间 */
-(UILabel *)totalTimeLab{
    if (!_totalTimeLab) {
        UILabel * totalLab = [[UILabel alloc]init];
        totalLab.font = [UIFont systemFontOfSize:14];
        totalLab.text = @"59:59";
        totalLab.adjustsFontSizeToFitWidth = YES;
        totalLab.textAlignment = NSTextAlignmentCenter;
        totalLab.textColor = [UIColor whiteColor];
        _totalTimeLab = totalLab;
    }
    return _totalTimeLab;
}



/** 播放进度条 */
- (UIProgressView *)progress{
    if (!_progress){
        _progress = [[UIProgressView alloc]init];
        _progress.progressTintColor = [UIColor whiteColor];
        _progress.trackTintColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
    }
    return _progress;
}

#pragma mark - 播放按钮
/** 播放按钮点击事件 */
- (void)playAction:(UIButton *)button{
    button.selected = !button.selected;
    if (_delegate && [_delegate respondsToSelector:@selector(playButtonAction:)]) {
        [_delegate playButtonAction:button.selected];
    }
}

#pragma mark - SliderMedth
/** 滑杆开始拖动 */
- (void)videoSliderDragBegan:(KTSlider *)slider{
    if (_delegate && [_delegate respondsToSelector:@selector(videoSliderDragBegan:)]) {
        [_delegate videoSliderDragBegan:slider];
    }
}

/** 滑杆拖动中 */
- (void)videoSliderDragingValueChanged:(KTSlider *)slider{
    if (_delegate && [_delegate respondsToSelector:@selector(videoSliderDragingValueChanged:)]) {
        [_delegate videoSliderDragingValueChanged:slider];
    }
}

/** 滑杆结束拖动 */
- (void)videoSliderDraged:(KTSlider *)slider{
    if (_delegate && [_delegate respondsToSelector:@selector(videoSliderDraged:)]) {
        [_delegate videoSliderDraged:slider];
    }
}

#pragma mark - 单双击事件
/** 控制面板单击事件 */
- (void)tap:(UIGestureRecognizer *)gesture{
    if (_delegate && [_delegate respondsToSelector:@selector(tapControllersViewGesture)]) {
        [_delegate tapControllersViewGesture];
    }
}

/** 控制面板双击事件 */
- (void)doubleTap:(UIGestureRecognizer *)gesture{
    if (_delegate && [_delegate respondsToSelector:@selector(doubleTapControllersViewGesture)]) {
        [_delegate doubleTapControllersViewGesture];
    }
}






@end
