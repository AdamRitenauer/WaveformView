//
//  WaveformView.h
//  AudioUIKit
//
//  Created by Adam Ritenauer on 8/27/16.
//  Copyright © 2016 Adam Ritenauer, Himself. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for AudioUIKit.
FOUNDATION_EXPORT double AudioUIKitVersionNumber;

//! Project version string for AudioUIKit.
FOUNDATION_EXPORT const unsigned char AudioUIKitVersionString[];

/**
	Displays the wave form of an audio file at any scale or resolution. Emphasises responsivness, displaying the visible portion of the wave form as quickly as possible, and efficient memory usage, never using unbounded memory.
 */
@interface WaveformView : UIView

/// The url to audio file display
@property (nonatomic, strong) NSURL *url;

/// Number of seconds of audio a single point represents, determines the scale of the produced image
@property (nonatomic, assign) CGFloat pointsPerSecond;

/// The color of the waveform
@property (nonatomic, assign) UIColor *waveColor;

@end
