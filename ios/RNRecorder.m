#import "RCTBridge.h"
#import "RNRecorder.h"
#import "RNRecorderManager.h"
#import "RCTLog.h"
#import "RCTUtils.h"

#import <AVFoundation/AVFoundation.h>

@implementation RNRecorder
{
   /* Required to publish events */
   RCTEventDispatcher *_eventDispatcher;
   /* SCRecorder instance */
   SCRecorder *_recorder;
   /* SCRecorder session instance */
   SCRecordSession *_session;
   /* Preview view ¨*/
   UIView *_previewView;
   /* Configuration */
   NSDictionary *_config;
   /* Camera type (front || back) */
   NSString *_device;
   
   /* Video format */
   NSString *_videoFormat;
   /* Video quality */
   NSString *_videoQuality;
   /* Video filters */
   NSArray *_videoFilters;
   
   /* Audio quality */
   NSString *_audioQuality;
}

#pragma mark - Init

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
   
   if ((self = [super init])) {
      if (_recorder == nil) {
         _recorder = [SCRecorder recorder];
         _recorder.captureSessionPreset = [SCRecorderTools bestCaptureSessionPresetCompatibleWithAllDevices];
         _recorder.delegate = self;
         _recorder.initializeSessionLazily = NO;
      }
   }
   return self;
}

#pragma mark - Setter

- (void)setConfig:(NSDictionary *)config
{
   _config = config;
   NSDictionary *video  = [RCTConvert NSDictionary:[config objectForKey:@"video"]];
   NSDictionary *audio  = [RCTConvert NSDictionary:[config objectForKey:@"audio"]];
   
   // Recorder config
   _recorder.autoSetVideoOrientation = [RCTConvert BOOL:[config objectForKey:@"autoSetVideoOrientation"]];

   // Flash config
   NSInteger flash = (int)[RCTConvert NSInteger:[config objectForKey:@"flashMode"]];
   _recorder.flashMode = flash;
   
   // Video config
   _recorder.videoConfiguration.enabled = [RCTConvert BOOL:[video objectForKey:@"enabled"]];
   _recorder.videoConfiguration.bitrate = [RCTConvert int:[video objectForKey:@"bitrate"]];
   _recorder.videoConfiguration.timeScale = [RCTConvert float:[video objectForKey:@"timescale"]];
   _videoFormat = [RCTConvert NSString:[video objectForKey:@"format"]];
   [self setVideoFormat:_videoFormat];
   _videoQuality = [RCTConvert NSString:[video objectForKey:@"quality"]];
   _videoFilters = [RCTConvert NSArray:[video objectForKey:@"filters"]];
   
   // Audio config
   _recorder.audioConfiguration.enabled = [RCTConvert BOOL:[audio objectForKey:@"enabled"]];
   _recorder.audioConfiguration.bitrate = [RCTConvert int:[audio objectForKey:@"bitrate"]];
   _recorder.audioConfiguration.channelsCount = [RCTConvert int:[audio objectForKey:@"channelsCount"]];
   _audioQuality = [RCTConvert NSString:[audio objectForKey:@"quality"]];

   // Audio format
   NSString *format = [RCTConvert NSString:[audio objectForKey:@"format"]];
   if ([format isEqual:@"MPEG4AAC"]) {
      _recorder.audioConfiguration.format = kAudioFormatMPEG4AAC;
   }
}

- (void)setDevice:(NSString*)device
{
   _device = device;
   if ([device  isEqual: @"front"]) {
      _recorder.device = AVCaptureDevicePositionFront;
   } else if ([device  isEqual: @"back"]) {
      _recorder.device = AVCaptureDevicePositionBack;
   }
}

- (void)setVideoFormat:(NSString*)format
{
   _videoFormat = format;
   if ([_videoFormat  isEqual: @"MPEG4"]) {
      _videoFormat = AVFileTypeMPEG4;
   } else if ([_videoFormat  isEqual: @"MOV"]) {
      _videoFormat = AVFileTypeQuickTimeMovie;
   }
   if (_session != nil) {
      _session.fileType = _videoFormat;
   }
}

#pragma mark - Private Methods

- (NSArray *)sortFilterKeys:(NSDictionary *)dictionary {
   
   NSArray *keys = [dictionary allKeys];
   NSArray *sortedKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      NSString *key1 = (NSString*)obj1;
      
      if ([key1 isEqualToString:@"CIfilter"] || [key1 isEqualToString:@"file"])
         return (NSComparisonResult)NSOrderedAscending;
      else
         return (NSComparisonResult)NSOrderedDescending;
   }];
   
   return sortedKeys;
}

- (SCFilter*)createFilter
{
   SCFilter *filter = [SCFilter emptyFilter];

   for (NSDictionary* subfilter in _videoFilters) {
      SCFilter *subscfilter = [SCFilter emptyFilter];
      NSArray *sortedKeys = [self sortFilterKeys:subfilter];
      
      for (NSString* propkey in sortedKeys) {
         
         // CIfilter specified
         if ([propkey isEqualToString:@"CIfilter"]) {
            NSString *name = [RCTConvert NSString:[subfilter objectForKey:propkey]];
            subscfilter = [SCFilter filterWithCIFilterName:name];
            if (subscfilter == nil) {
               RCTLogError(@"CIfilter %@ not found", name);
               subscfilter = [SCFilter emptyFilter];
            }
         }
         // Filter file specified
         else if ([propkey isEqualToString:@"file"]) {
            NSString *path = [RCTConvert NSString:[subfilter objectForKey:propkey]];
            subscfilter = [SCFilter filterWithContentsOfURL:[[NSBundle mainBundle] URLForResource:path withExtension:@"cisf"]];
            if (subscfilter == nil) {
               RCTLogError(@"CSIF file %@ not found", path);
               subscfilter = [SCFilter emptyFilter];
            }
         }
         // Animations specified
         else if ([propkey isEqualToString:@"animations"]) {
            NSArray *animations = [RCTConvert NSArray:[subfilter objectForKey:propkey]];

            for (NSDictionary* anim in animations) {
               NSString *name = [RCTConvert NSString:[anim objectForKey:@"name"]];
               NSNumber *startValue = [RCTConvert NSNumber:[anim objectForKey:@"startValue"]];
               NSNumber *endValue = [RCTConvert NSNumber:[anim objectForKey:@"endValue"]];
               double   startTime = [RCTConvert double:[anim objectForKey:@"startTime"]];
               double   duration = [RCTConvert double:[anim objectForKey:@"duration"]];

               [subscfilter addAnimationForParameterKey:name startValue:startValue endValue:endValue startTime:startTime duration:duration];
            }
         }
         else {
            NSNumber *val = [RCTConvert NSNumber:[subfilter objectForKey:propkey]];
            [subscfilter setParameterValue:val forKey:propkey];
         }
      }
      [filter addSubFilter:subscfilter];
   }
   return filter;
}

- (NSString*)saveImage:(UIImage*)image
{
   NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
   NSString *name = [[NSProcessInfo processInfo] globallyUniqueString];
   name = [name stringByAppendingString:@".png"];
   NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:name];
   
   [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
   return filePath;
}

#pragma mark - Public Methods

- (void)record
{
   [_recorder record];
}

- (void)capture:(void(^)(NSError *error, NSString *url))callback
{
   [_recorder capturePhoto:^(NSError *error, UIImage *image) {
      NSString *imgPath = [self saveImage:image];
      callback(error, imgPath);
   }];
}

- (void)pause:(void(^)())completionHandler
{
   [_recorder pause:completionHandler];
}

- (SCRecordSessionSegment*)lastSegment
{
   return [_session.segments lastObject];
}

- (void)removeLastSegment
{
   [_session removeLastSegment];
}

- (void)removeAllSegments
{
   [_session removeAllSegments:true];
}

- (void)removeSegmentAtIndex:(NSInteger)index
{
   [_session removeSegmentAtIndex:index deleteFile:true];
}

- (void)save:(void(^)(NSError *error, NSURL *outputUrl))callback
{
   AVAsset *asset = _session.assetRepresentingSegments;
   SCAssetExportSession *assetExportSession = [[SCAssetExportSession alloc] initWithAsset:asset];
   assetExportSession.outputFileType = _videoFormat;
   assetExportSession.outputUrl = [_session outputUrl];
   assetExportSession.videoConfiguration.preset = _videoQuality;
   assetExportSession.audioConfiguration.preset = _audioQuality;
   
   // Apply filters
   assetExportSession.videoConfiguration.filter = [self createFilter];

   [assetExportSession exportAsynchronouslyWithCompletionHandler: ^{
      callback(assetExportSession.error, assetExportSession.outputUrl);
   }];
}


#pragma mark - SCRecorder events

- (void)recorder:(SCRecorder *)recorder didInitializeAudioInSession:(SCRecordSession *)recordSession error:(NSError *)error {
   if (error == nil) {
      NSLog(@"Initialized audio in record session");
   } else {
      NSLog(@"Failed to initialize audio in record session: %@", error.localizedDescription);
   }
}

- (void)recorder:(SCRecorder *)recorder didInitializeVideoInSession:(SCRecordSession *)recordSession error:(NSError *)error {
   if (error == nil) {
      NSLog(@"Initialized video in record session");
   } else {
      NSLog(@"Failed to initialize video in record session: %@", error.localizedDescription);
   }
}

#pragma mark - React View Management


- (void)layoutSubviews
{
   [super layoutSubviews];
   
   if (_previewView == nil) {
      _previewView = [[UIView alloc] initWithFrame:self.bounds];
      _recorder.previewView = _previewView;
      [_previewView setBackgroundColor:[UIColor blackColor]];
      [self insertSubview:_previewView atIndex:0];
      [_recorder startRunning];
   
      _session = [SCRecordSession recordSession];
      [self setVideoFormat:_videoFormat];
      _recorder.session = _session;
   }
   
   return;
}

- (void)insertReactSubview:(UIView *)view atIndex:(NSInteger)atIndex
{
   [self addSubview:view];
}

- (void)removeReactSubview:(UIView *)subview
{
   [subview removeFromSuperview];
}

- (void)removeFromSuperview
{
   [super removeFromSuperview];
}

- (void)orientationChanged:(NSNotification *)notification
{
   [_recorder previewViewFrameChanged];
}

@end