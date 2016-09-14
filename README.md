# WaveformView
A UIView subclass for displaying the waveform of an audio file at a specified resolution.

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Features
* Render a Waveform any resolution (specified in the points per second of audio) 
* CATiledLayer backed view allows for responsive rendering. Only the visible portion of the waveform is rendered
* Renders directly from audio data. Eliminating the need to store large UIImages in memory or on disk

## Installation

Using [Carthage](https://github.com/Carthage/Carthage):

```
GitHub "AdamRitenauer/WaveformView" ~> 0.0.1
``` 
## A Note On The Example App

To run the example you will need to provide your own demo media. Simply copy an audio file "WaveformView Example/demo.mp3"

