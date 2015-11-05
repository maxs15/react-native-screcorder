/* React dependencies */
var React = require('react-native');
var screen = require('Dimensions').get('window');

var {
  StyleSheet
} = React;

module.exports = StyleSheet.create({

	wrapper: {
		flex: 1
	},

	barWrapper: {
		width: screen.width,
		height: 10,
		backgroundColor: "black",
		opacity: 0.3
	},

	barGauge: {
		width: 0,
		height: 10,
		backgroundColor: "red"
	},

	controls: {
		position: 'absolute',
		bottom: 50,
		width: screen.width,
		flexDirection: 'row',
		flexWrap: "wrap",
		justifyContent: 'space-around',
		alignItems: 'center',
		backgroundColor: 'transparent',
		opacity: 0.6
	},

	controlBtn: {
		backgroundColor: "white",
		padding: 20,
		opacity: 0.8,
		borderRadius: 5,
		marginBottom: 10
	},

	infoBtn: {
		backgroundColor: "#2ecc71",
		opacity: 0.8,
		padding: 10,
		position: 'absolute',
		top: 20,
		right: 20,
		opacity: 0.7,
		borderRadius: 5
	},

	infoBtnText: {
		color: "white"
	}

});