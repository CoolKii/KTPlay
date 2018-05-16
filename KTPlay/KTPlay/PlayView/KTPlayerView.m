//
//  KTPlayerView.m
//  KTPlay
//
//  Created by Ki on 2018/5/16.
//  Copyright © 2018年 Ki. All rights reserved.
//

#import "KTPlayerView.h"
#import <AVFoundation/AVFoundation.h>

/** 播放器的播放状态 */
typedef NS_ENUM(NSInteger, KTVideoPlayerState) {
    KTVideoPlayerStateFailed,     // 播放失败
    KTVideoPlayerStateBuffering,  // 缓冲中
    KTVideoPlayerStatePlaying,    // 播放中
    KTVideoPlayerStatePause,      // 暂停播放
};

@interface KTPlayerView ()

/** 播放器 */
@property (nonatomic, strong) AVPlayerItem * playerItem;
/** 播放器item */
@property (nonatomic, strong) AVPlayer * player;
/** 播放器layer */
@property (nonatomic, strong) AVPlayerLayer * playerLayer;
/** 播放器的播放状态 */
@property (nonatomic, assign) KTVideoPlayerState playerState;

@end

@implementation KTPlayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self creatPlayer];
        [self creatUI];
    }
    return self;
}

- (void)creatPlayer{
    
    NSURL * url  = [NSURL URLWithString:@"http://120.25.226.186:32812/resources/videos/minion_02.mp4"];
    
    AVPlayerItem * playerItem = [[AVPlayerItem alloc]initWithURL:url];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    // 缓冲区空了，需要等待数据
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    // 缓冲区有足够数据可以播放了
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    self.playerItem = playerItem;
    
    AVPlayer * player = [[AVPlayer alloc]initWithPlayerItem:playerItem];
    self.player = player;
    
    AVPlayerLayer * playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = self.bounds;
    
    [self.layer addSublayer:playerLayer];
    
    [player play];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.playerLayer.frame = self.bounds;
}

/** 视频播放结束事件监听 */
- (void)videoDidPlayToEnd:(NSNotification *)notify
{
    [_player seekToTime:CMTimeMake(0, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [_player play];
}

#pragma mark - 监听播放器事件
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        // 计算缓冲进度
        NSTimeInterval timeInterval = [self availableDuration];
        CMTime duration = self.playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        // 当无缓冲视频数据时
        if (self.playerItem.playbackBufferEmpty) {
            self.playerState = KTVideoPlayerStateBuffering;
            [self bufferingSomeSecond];
        }
    }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"])
    {
        // 当视频缓冲好时
        if (self.playerItem.playbackLikelyToKeepUp && self.playerState == KTVideoPlayerStateBuffering){
            self.playerState = KTVideoPlayerStatePlaying;
        }
    }
    else if ([keyPath isEqualToString:@"status"])
    {
        if (self.player.currentItem.status == AVPlayerStatusReadyToPlay) {
            [self setNeedsLayout];
            [self layoutIfNeeded];
            [self.layer insertSublayer:_playerLayer atIndex:0];
            self.playerState = KTVideoPlayerStatePlaying;
        }
        else if (self.player.currentItem.status == AVPlayerItemStatusFailed) {
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

- (void)creatUI{
    
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
      [_player pause];
    __weak __typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf.player play];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp){
            [self bufferingSomeSecond];
        }
    });
}

@end
