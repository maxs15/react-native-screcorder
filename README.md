# react-native-screcorder

A react native component to capture pictures and record Video with Vine-like tap to record, animatable filters, slow motion, segments editing.  
Based on this awesome library [SCRecorder](https://github.com/rFlex/SCRecorder).

## Getting started

1. `npm install react-native-screcorder@latest --save`
2. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
3. Go to `node_modules` ➜ `react-native-recorder` and add `RNRecorder.xcodeproj`
4. In XCode, in the project navigator, select your project. Add `libRNRecorder.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
5. Click `RNRecorder.xcodeproj` in the project navigator and go the `Build Settings` tab. Make sure 'All' is toggled on (instead of 'Basic'). Look for `Header Search Paths` and make sure it contains both `$(SRCROOT)/../react-native/React` and `$(SRCROOT)/../../React` - mark both as `recursive`.
5. Run your project (`Cmd+R`)

## Example
Check [index.ios.js](https://github.com/maxs15/react-native-screcorder/blob/master/Example/index.ios.js) in the Example folder.

## Properties

#### `config`

Configure the recorder
See below the full options available:
The filters are applied on the saved video

```javascript
{
  autoSetVideoOrientation: false,

  video: {
    enabled: true,
    bitrate: 2000000, // 2Mbit/s
    timescale: 1, // Higher than 1 makes a slow motion, between 0 and 1 makes a timelapse effect
    format: "MPEG4",
    quality: "HighestQuality", // HighestQuality || MediumQuality || LowQuality
    filters: [
      {
        "CIfilter": "CIColorControls",
        "animations": [{
          "name": "inputSaturation",
          "startValue": 100,
          "endValue": 0,
          "startTime": 0,
          "duration": 0.5
        }]
      },
      {"file": "b_filter"},
      {"CIfilter":"CIColorControls", "inputSaturation": 0},
      {"CIfilter":"CIExposureAdjust", "inputEV": 0.7}
    ]
  },
  audio: {
    enabled: true,
    bitrate: 128000, // 128kbit/s
    channelsCount: 1, // Mono output
    format: "MPEG4AAC",
    quality: "HighestQuality" // HighestQuality || MediumQuality || LowQuality
  }
};
```

#### `device`

Values: "front" or "back"
Specify wihich camera to use

#### `onNewSegment`

Will call the specified method when a new segment has been recorded


## Component methods

You can access component methods by adding a `ref` (ie. `ref="recorder"`) prop to your `<Recorder>` element, then you can use `this.refs.recorder.record()`, etc. inside your component.

#### `capture(callback)`
Capture a picture

#### `record()`
Start the recording of a new segment

#### `pause()`
Stop the recording of the segment

#### `save(callback)`
Generate a video with the recorded segments, if filters have been specified in the configuration they will be applied

#### `removeLastSegment()`
Remove the last segment

#### `removeAllSegments()`
Remove all the segments

#### `removeSegmentAtIndex(index)`
Remove segment at the specified index
