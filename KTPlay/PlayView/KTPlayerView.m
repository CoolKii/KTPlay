//
//  KTPlayerView.m
//  KTPlay
//
//  Created by Ki on 2018/5/16.
//  Copyright © 2018年 Ki. All rights reserved.
//

#import "KTPlayerView.h"
#import "ControlsView.h"
#import <AVFoundation/AVFoundation.h>
#import "KTSlider.h"

/** 播放器的播放状态 */
typedef NS_ENUM(NSInteger, KTVideoPlayerState) {
    KTVideoPlayerStateFailed,     // 播放失败
    KTVideoPlayerStateBuffering,  // 缓冲中
    KTVideoPlayerStatePlaying,    // 播放中
    KTVideoPlayerStatePause,      // 暂停播放
};

@interface KTPlayerView ()<ControllersViewDelegate>

/** 播放器 */
@property (nonatomic, strong) AVPlayerItem * playerItem;
/** 播放器item */
@property (nonatomic, strong) AVPlayer * player;
/** 播放器layer */
@property (nonatomic, strong) AVPlayerLayer * playerLayer;
/** 播放器的播放状态 */
@property (nonatomic, assign) KTVideoPlayerState playerState;
/** 时间监听器 */
@property (nonatomic, strong) id timeObserve;
/** 是否结束播放 */
@property (nonatomic, assign) BOOL playDidEnd;

@property (nonatomic,strong)ControlsView  * controllersView;

@end

@implementation KTPlayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self creatPlayer];
       [self addSubview:self.controllersView];
    }
    return self;
}

- (void)creatPlayer{

    AVPlayer * player = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
    self.player = player;
    
    AVPlayerLayer * playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = self.bounds;
    
    [self.layer addSublayer:playerLayer];
    
    self.backgroundColor = [UIColor blackColor];
    
    [self createTimer];
}


-(ControlsView *)controllersView{
    if (!_controllersView) {
        ControlsView * controllersView = [[ControlsView alloc] init];
        controllersView.delegate = self;
        _controllersView = controllersView;
    }
    return  _controllersView;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
    self.controllersView.frame = self.bounds;
}

/** 视频播放结束事件监听 */
- (void)videoDidPlayToEnd:(NSNotification *)notify{
    [_player seekToTime:CMTimeMake(0, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self playerPause];
}

/** 创建定时器 */
- (void)createTimer {
    __weak typeof(self) weakSelf = self;
    self.timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:nil usingBlock:^(CMTime time){
        AVPlayerItem *currentItem = weakSelf.playerItem;
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0) {
            NSInteger currentTime = (NSInteger)CMTimeGetSeconds([currentItem currentTime]);
            CGFloat totalTime = (CGFloat)currentItem.duration.value / currentItem.duration.timescale;
            CGFloat value = CMTimeGetSeconds([currentItem currentTime]) / totalTime;
            [weakSelf.controllersView _setPlaybackControlsWithPlayTime:currentTime totalTime:totalTime sliderValue:value];
        }
    }];
}

-(AVPlayerItem *)playerItem{
    if (!_playerItem) {
        
        NSURL * url  = [NSURL URLWithString:@"http://120.25.226.186:32812/resources/videos/minion_02.mp4"];
        AVPlayerItem * playerItem = [[AVPlayerItem alloc]initWithURL:url];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区空了，需要等待数据
        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区有足够数据可以播放了
        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
        _playerItem = playerItem;
    }
    return _playerItem;
}

#pragma mark - 监听播放器事件
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        // 计算缓冲进度
        NSTimeInterval timeInterval = [self availableDuration];
        CMTime duration = self.playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        self.controllersView.progressValue = timeInterval/totalDuration;
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        // 当无缓冲视频数据时
        NSLog(@"缓冲为空 ！");
        if (self.playerItem.playbackBufferEmpty) {
            self.playerState = KTVideoPlayerStateBuffering;
            [self bufferingSomeSecond];
        }
    }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        // 当视频缓冲好时
        NSLog(@"缓冲 好了 ！");
        if (self.playerItem.playbackLikelyToKeepUp && self.playerState == KTVideoPlayerStateBuffering){
            self.playerState = KTVideoPlayerStatePlaying;
        }
    }
    else if ([keyPath isEqualToString:@"status"])
    {
        if (self.player.currentItem.status == AVPlayerStatusReadyToPlay) {
            NSLog(@" 准备 播放");
            [self setNeedsLayout];
            [self layoutIfNeeded];
            [self.layer insertSublayer:_playerLayer atIndex:0];
            [self playerPlay];
            self.playerState = KTVideoPlayerStatePlaying;
        }else if (self.player.currentItem.status == AVPlayerItemStatusFailed) {
            NSLog(@" 播放 失败！");
            self.playerState = KTVideoPlayerStateFailed;
        }
        
    }
}

/**
 @param playerState 播放器的播放状态
 */
- (void)setPlayerState:(KTVideoPlayerState)playerState
{
    _playerState = playerState;
    switch (_playerState) {
        case KTVideoPlayerStateBuffering:
        {
        }
            break;
        case KTVideoPlayerStatePlaying:
        {
            
        }
            break;
        case KTVideoPlayerStateFailed:
        {
        }
            break;
        default:
            break;
    }
}

/**
 *  计算缓冲进度
 *  @return 缓冲进度
 */
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

/**
 *  缓冲较差时候回调这里
 */
- (void)bufferingSomeSecond {
    self.playerState = KTVideoPlayerStateBuffering;
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    __block BOOL isBuffering = NO;
    if (isBuffering) return;
    isBuffering = YES;
    
    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
      [self playerPause];
    __weak __typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf playerPlay];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp){
            [self bufferingSomeSecond];
        }
    });
}

#pragma mark - ControllersViewDelegate
/**
 播放按钮点击事件
 @param selected 按钮选中状态
 */
- (void)playButtonAction:(BOOL)selected{
    if (selected){
        [self playerPause];
    }else{
        [self playerPlay];
    }
}

/** 全屏切换按钮点击事件 */
- (void)fullScreenButtonAction{
    
}

- (void)retryButtonAction{
    
}

/** 滑杆开始拖动 */
- (void)videoSliderDragBegan:(KTSlider *)slider{
    [self playerPause];
}
/** 滑杆拖动中 */
- (void)videoSliderDragingValueChanged:(KTSlider *)slider{
    CGFloat totalTime = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;
    CGFloat dragedSeconds = totalTime * slider.value;
    //转换成CMTime才能给player来控制播放进度
    CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1);
    [_player seekToTime:dragedCMTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    NSInteger currentTime = (NSInteger)CMTimeGetSeconds(dragedCMTime);
    [self.controllersView _setPlaybackControlsWithPlayTime:currentTime totalTime:totalTime sliderValue:slider.value];
}
/** 滑杆结束拖动 */
- (void)videoSliderDraged:(KTSlider *)slider{
    
    if (slider.value != 1) {
        self.playDidEnd = NO;
    }
    if (!self.playerItem.isPlaybackLikelyToKeepUp) {
        [self bufferingSomeSecond];
    }else{
        //继续播放
        [self playerPlay];
    }
}

/** 控制面板单击事件 */
- (void)tapControllersViewGesture{
    
}

/** 控制面板双击事件 */
- (void)doubleTapControllersViewGesture{
    
}

#pragma mark - 播放器 播放 Or 暂停
- (void)playerPause{
     [self.player pause];
    [self.controllersView playerStatus:YES];
}

- (void)playerPlay{
    [self.player play];
    [self.controllersView playerStatus:NO];
}













@end
