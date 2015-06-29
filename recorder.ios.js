var React = require('React');
var DeviceEventEmitter = require('RCTDeviceEventEmitter');
var NativeModules = require('NativeModules');
var ReactNativeViewAttributes = require('ReactNativeViewAttributes');
var StyleSheet = require('StyleSheet');
var View = require('View');
var createReactNativeComponentClass = require('createReactNativeComponentClass');
var PropTypes = require('ReactPropTypes');
var StyleSheetPropType = require('StyleSheetPropType');
var NativeMethodsMixin = require('NativeMethodsMixin');
var merge = require('merge');

/******* ENUM **********/

var constants = {
  // Flash enum
  SCFlashModeOff: 0,
  SCFlashModeOn: 1,
  SCFlashModeAuto: 2
};

/******* STYLES **********/

var styles = StyleSheet.create({
  wrapper: {
    flex: 1,
    backgroundColor: "transparent"
  }
});

/******* RECORDER COMPONENT **********/

var Recorder = React.createClass({
  propTypes: {
  },

  mixins: [NativeMethodsMixin],

  viewConfig: {
    uiViewClassName: 'UIView',
    validAttributes: ReactNativeViewAttributes.UIView
  },

  /*** PUBLIC METHODS ***/

  // Start recording of the current session
  record() {
    NativeModules.RNRecorderManager.record();
  },

  // Capture a picture
  capture(callback) {
    NativeModules.RNRecorderManager.capture(callback);
  },

  // Pause recording of the current session
  pause() {

    var onNewSegment = this.props.onNewSegment || function() {};

    NativeModules.RNRecorderManager.pause(onNewSegment);
  },

  // Save the recording
  save(callback) {
    NativeModules.RNRecorderManager.save(callback);
  },

  // Remove last segment of the session
  removeLastSegment() {
    NativeModules.RNRecorderManager.removeLastSegment();
  },

  // Remove all segments of the session
  removeAllSegments() {
    NativeModules.RNRecorderManager.removeAllSegments();
  },

  // Remove segment at the specified index
  removeSegmentAtIndex(index) {
    NativeModules.RNRecorderManager.removeSegmentAtIndex(index);
  },

  /*** RENDER ***/

  render() {


    var config = merge({
      autoSetVideoOrientation: false,
      flashMode: constants.SCFlashModeOff,

      video: {
        enabled: true,
        bitrate: 2000000, // 2Mbit/s
        timescale: 1, // Higher than 1 makes a slow motion, between 0 and 1 makes a timelapse effect
        format: "MPEG4",
        quality: "HighestQuality", // HighestQuality || MediumQuality || LowQuality
        filters: [
          /*{
            "CIfilter": "CIColorControls",
            "animations": [{
              "name": "inputSaturation",
              "startValue": 100,
              "endValue": 0,
              "startTime": 0,
              "duration": 0.5
            }]
          },*/
          /*{"file": "b_filter"},*/
          /*{"CIfilter":"CIColorControls", "inputSaturation": 0},
          {"CIfilter":"CIExposureAdjust", "inputEV": 0.7}*/
        ]
      },
      audio: {
        enabled: true,
        bitrate: 128000, // 128kbit/s
        channelsCount: 1, // Mono output
        format: "MPEG4AAC",
        quality: "HighestQuality" // HighestQuality || MediumQuality || LowQuality
      }

    },this.props.config);

    var nativeProps = merge(this.props, {
      config: config,
      device: this.props.device || "front"
    });

    return (
      <RNRecorder {...nativeProps}>
        <View style={styles.wrapper}>{this.props.children}</View>
      </RNRecorder>
    );
  }

});

var RNRecorder = createReactNativeComponentClass({
  validAttributes: merge(ReactNativeViewAttributes.UIView, {
    config: true,
    device: true
  }),
  uiViewClassName: 'RNRecorder',
});

Recorder.constants = constants;

module.exports = Recorder;
