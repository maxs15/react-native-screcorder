#import "RNRecorderManager.h"
#import "RNRecorder.h"

#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import "UIView+React.h"

@implementation RNRecorderManager
{
    RNRecorder *_recorderView;
}

RCT_EXPORT_MODULE();
RCT_EXPORT_VIEW_PROPERTY(config, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(device, NSString);

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (UIView *)view
{
    // Alloc UI element
    if (_recorderView == nil) {
        _recorderView = [[RNRecorder alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
    }
    return _recorderView;
}

RCT_EXPORT_METHOD(record)
{
    [_recorderView record];
}

RCT_EXPORT_METHOD(capture:(RCTResponseSenderBlock)callback)
{
    [_recorderView capture:^(NSError *error, NSString *url) {
        if (error == nil && url != nil) {
            callback(@[[NSNull null], url]);
        } else {
            callback(@[[error localizedDescription], [NSNull null]]);
        }
    }];
}

RCT_EXPORT_METHOD(pause:(RCTResponseSenderBlock)callback)
{
    [_recorderView pause:^{
        
        SCRecordSessionSegment* ls = [_recorderView lastSegment];
        
        if (ls != nil) {
            NSString *thumbnail = [_recorderView saveImage:ls.thumbnail];
            NSString *url = [ls.url relativeString];
            float duration = CMTimeGetSeconds(ls.duration);

            NSDictionary *props = @{@"url": url, @"thumbnail":thumbnail, @"duration":@(duration)};
            callback(@[props]);
        }
    
    }];
}

RCT_EXPORT_METHOD(removeLastSegment)
{
    [_recorderView removeLastSegment];
}

RCT_EXPORT_METHOD(removeAllSegments)
{
    [_recorderView removeAllSegments];
}

RCT_EXPORT_METHOD(removeSegmentAtIndex:(NSInteger)index)
{
    [_recorderView removeSegmentAtIndex:index];
}

RCT_EXPORT_METHOD(save:(RCTResponseSenderBlock)callback)
{
    [_recorderView save:^(NSError *error, NSURL *url) {
        if (error == nil && url != nil) {
            callback(@[[NSNull null], [url relativeString]]);
        } else {
            callback(@[[error localizedDescription], [NSNull null]]);
        }
    }];
}

@end