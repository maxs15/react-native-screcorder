/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 */
'use strict';

var React = require('react-native');
var {
  AppRegistry,
  View,
  Animated,
  StatusBarIOS,
  TouchableOpacity,
  TouchableWithoutFeedback,
  Text,
  NavigatorIOS
} = React;

var styles    = require('./style');
var screen    = require('Dimensions').get('window');
var Recorder  = require('react-native-screcorder');
var Video     = require('react-native-video');


/*********** RECORDER COMPONENT ***********/

var Record = React.createClass({

  getInitialState: function() {
    return {
      device: "front",
      recording: false,
      nbSegments: 0,
      barPosition: new Animated.Value(0),
      currentDuration: 0,
      maxDuration: 3000,
      limitReached: false,
      config: {
        flashMode: Recorder.constants.SCFlashModeOff,
        video: {
          enabled: true,
          format: 'MPEG4',
        },
      }
    }
  },

  componentDidMount: function() {
    StatusBarIOS.setHidden(true, "slide");
  },

  /*
   *  PRIVATE METHODS
   */

  startBarAnimation: function() {
    this.animRunning = true;
    this.animBar = Animated.timing(
      this.state.barPosition,
      {
        toValue: screen.width,
        duration: this.state.maxDuration - this.state.currentDuration
      }
    );
    this.animBar.start(() => {
      // The video duration limit has been reached
      if (this.animRunning) {
        this.finish();
      }
    });
  },

  resetBarAnimation: function() {
    Animated.spring(this.state.barPosition, {toValue: 0}).start();
  },

  stopBarAnimation: function() {
    this.animRunning = false;
    if (this.animBar)
      this.animBar.stop();
  },

  /*
   *  PUBLIC METHODS
   */

  record: function() {
    if (this.state.limitReached) return;
    this.refs.recorder.record();
    this.startBarAnimation();
    this.setState({recording: true});
  },

  pause: function(limitReached) {
    if (!this.state.recording) return;
    this.refs.recorder.pause();
    this.stopBarAnimation();
    this.setState({recording: false, nbSegments: ++this.state.nbSegments});
  },

  finish: function() {
    this.stopBarAnimation();
    this.refs.recorder.pause();
    this.setState({recording: false, limitReached: true, nbSegments: ++this.state.nbSegments});
  },

  reset: function() {
    this.resetBarAnimation();
    this.refs.recorder.removeAllSegments();
    this.setState({
      recording: false,
      nbSegments: 0,
      currentDuration: 0,
      limitReached: false
    });
  },

  preview: function() {
    this.refs.recorder.save((err, url) => {
      console.log('url = ', url);
      this.props.navigator.push({component: Preview, passProps: {video: url}});
    });
  },

  setDevice: function() {
    var device = (this.state.device == "front") ? "back" : "front";
    this.setState({device: device});
  },

  toggleFlash: function() {
    if (this.state.config.flashMode == Recorder.constants.SCFlashModeOff) {
      this.state.config.flashMode = Recorder.constants.SCFlashModeLight;
    } else {
      this.state.config.flashMode = Recorder.constants.SCFlashModeOff;
    }
    this.setState({config: this.state.config});
  },

  /*
   *  EVENTS
   */

  onRecordDone: function() {
    this.setState({nbSegments: 0});
  },

  onNewSegment: function(segment) {
    console.log('segment = ', segment);
    this.state.currentDuration += segment.duration * 1000;
  },

  /*
   *  RENDER METHODS
   */

  renderBar: function() {
    return (
      <View style={styles.barWrapper}>
        <Animated.View style={[styles.barGauge, {width: this.state.barPosition}]}/>
      </View>
    );
  },

  render: function() {
    var bar     = this.renderBar();
    var control = null;

    if (!this.state.limitReached) {
      control = (
        <TouchableOpacity onPressIn={this.record} onPressOut={this.pause} style={styles.controlBtn}>
          <Text>Record</Text>
        </TouchableOpacity>
      );
    }

    return (
      <Recorder
        ref="recorder"
        config={this.state.config}
        device={this.state.device}
        onNewSegment={this.onNewSegment}
        style={styles.wrapper}>
        {bar}
        <View style={styles.infoBtn}>
          <Text style={styles.infoBtnText}>{this.state.nbSegments}</Text>
        </View>
        <View style={styles.controls}>
          {control}
          <TouchableOpacity onPressIn={this.reset} style={styles.controlBtn}>
            <Text>Reset</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={this.preview} style={styles.controlBtn}>
            <Text>Preview</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={this.toggleFlash} style={styles.controlBtn}>
            <Text>Flash</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={this.setDevice} style={styles.controlBtn}>
            <Text>Switch</Text>
          </TouchableOpacity>
        </View>
      </Recorder>
    );
  }

});

/*********** PREVIEW COMPONENT ***********/

var Preview = React.createClass({

  getInitialState: function() {
    return {
      paused: false
    };
  },

  goBack: function() {
    this.setState({paused: true});
    this.props.navigator.pop();
  },

  render: function() {
    return (
      <TouchableWithoutFeedback onPress={this.goBack}>
        <Video
          source={{uri: this.props.video}}
          style={styles.wrapper}
          muted={false}
          resizeMode="cover"
          paused={this.state.paused}
          repeat={true}/>
      </TouchableWithoutFeedback>
    );
  }

});

/*********** APP COMPONENT ***********/

var App = React.createClass({

  render: function() {
    return (
      <NavigatorIOS initialRoute={{component: Record}} style={{flex: 1}} navigationBarHidden={true}/>
    );
  }
});

AppRegistry.registerComponent('Example', () => App);
