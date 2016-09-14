//
//  WaveformView.m
//  AudioUIKit
//
//  Created by Adam Ritenauer on 8/27/16.
//  Copyright © 2016 Adam Ritenauer, Himself. All rights reserved.
//

#import "WaveformView.h"
#import "WaveformLayer.h"
#import "AudioBufferListHelpers.h"
#import <AudioToolbox/AudioToolbox.h>

@interface WaveformView()

/// A reference to the audio file from which we will be reading
@property (nonatomic, assign) ExtAudioFileRef audioFile;

/// Synchronizes access to the audioFile
@property (nonatomic, strong) dispatch_queue_t audioFileQueue;

/// The format to which the file will be converted before processing
@property (nonatomic, assign) AudioStreamBasicDescription asbd;

/// The size of the audioFile in frames
@property (nonatomic, readonly) UInt32 fileSize;

/// The number of frames need to calculate one point
@property (nonatomic, assign) Float64 framesPerBin;

@end

@implementation WaveformView

#pragma mark - Init

- (instancetype)init {
	
	WaveformView *s = [super init];
	if (s)
		[self setup];
	return s;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	WaveformView *s = [super initWithCoder:aDecoder];
	if (s)
		[self setup];
	return s;
}

- (instancetype)initWithFrame:(CGRect)frame {
	
	WaveformView *s = [super initWithFrame:frame];
	if (s)
		[self setup];
	return s;
}

- (void) setup {
	
	// Set the LPCM format that we are to read
	AudioStreamBasicDescription asbd = {
		
		44100.0, //Float64 mSampleRate;
		kAudioFormatLinearPCM, //AudioFormatID mFormatID;
		kAudioFormatFlagsNativeFloatPacked, //AudioFormatFlags mFormatFlags;
		8, //UInt32 mBytesPerPacket;
		1, //UInt32 mFramesPerPacket;
		8, //UInt32 mBytesPerFrame;
		2, //UInt32 mChannelsPerFrame;
		32, //UInt32 mBitsPerChannel;
		0 //UInt32 mReserved;
	};
	self.asbd = asbd;
	
	//Create GCD Queues
	self.audioFileQueue = dispatch_queue_create("AudioUIKit.WaveformView.audioFileQueue", DISPATCH_QUEUE_SERIAL);
}

#pragma mark - Properties

- (void)setUrl:(NSURL *)url {
	
	_url = url;
	
	// Open the audio file
	self.audioFile = [WaveformView openAudioFileAtURL:url withASBD:self.asbd];
}

#pragma mark - UIView

+(Class)layerClass {
	
	// Use a custom tiled layer to execute drawRet in the background
	return [WaveformLayer class];
}

- (void)drawRect:(CGRect)originalRect {
	
	// Over draw the tile by 1 pixel, to elimiante small gaps between tiles
	CGRect rect = CGRectInset(originalRect, -0.5, -0.5);
	rect = CGRectOffset(rect, 0.5, 0.5);
	
	// Generate display data, since we're using tiled layer
	// drawRect is executed on a background thread
	NSData *displayData = [self aggregateAudioDataForRect:rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	NSUInteger numBins = displayData.length / sizeof(Float32);
	
	for(int bin = 0; bin < numBins; bin++) {
	
		CGFloat y = CGRectGetMinY(rect) + bin;
		
		Float32 binValue = *(((Float32 *)displayData.bytes) + (int)bin);
		
		CGFloat width = floor(binValue * CGRectGetWidth(self.bounds));
		CGFloat x = floor((CGRectGetWidth(self.bounds) / 2) - (width / 2));
		CGRect lineRect = CGRectMake(x, y, width, 1);
		
		if(CGRectIntersectsRect(rect, lineRect)){
			
			CGRect intersection = CGRectIntersection(rect, lineRect);
			
			CGFloat from = CGRectGetMinX(intersection);
			CGFloat to = CGRectGetMaxX(intersection);
			
			CGContextMoveToPoint(context, from, y);
			CGContextAddLineToPoint(context, to, y);
		}
	}

	CGContextSetStrokeColorWithColor(context, self.waveColor.CGColor);
	CGContextStrokePath(context);
}

- (void) didMoveToWindow {
	
	// Set Defaults
	if (!self.waveColor)
		self.waveColor = [UIColor blackColor];
	
	if (!self.pointsPerSecond)
		self.pointsPerSecond = 100;
	
	UInt32 framesPerBin = (1 / self.pointsPerSecond) * self.asbd.mSampleRate;
	self.framesPerBin = framesPerBin;
	
	// Calculate a maximum tileSize that divides evenly by the view's scale factor
	// CATiledLayer has a maximum tileSize of 1024. 5.5" devices have a scale factor of 3
	// If the tileSize is clamped on such a device drawRect will be called with a fractional
	// CGRect since 1024 / 3 = 341.33333.... Since pixels are
	// atomic we would like to avoid this.
	CGFloat cleanClamp = floor(1024 / self.contentScaleFactor) * self.contentScaleFactor;
	
	CGFloat tileWidth = CGRectGetWidth(self.frame) * self.contentScaleFactor / 2;
	tileWidth = MIN(tileWidth, cleanClamp);
	
	CGFloat tileHeight = CGRectGetHeight(self.frame)  * self.contentScaleFactor / 2;
	tileHeight = MIN(tileHeight, cleanClamp);
	
	((CATiledLayer *)self.layer).tileSize = CGSizeMake(tileWidth, tileHeight);
	((CATiledLayer *)self.layer).levelsOfDetail = 1;
	((CATiledLayer *)self.layer).levelsOfDetailBias = 0;
}

- (CGSize) intrinsicContentSize {
	
	// Use the size of the file to determine the views height
	
	SInt64 numFrames = [self fileSize];
	
	if (numFrames < 0)
		return  CGSizeMake(UIViewNoIntrinsicMetric, 0);
		
	CGFloat height = floor((numFrames / self.asbd.mSampleRate) * self.pointsPerSecond);
	
	CGSize size = CGSizeMake(UIViewNoIntrinsicMetric, height);
	
	return size;
}

#pragma mark - Convenience Properties

- (UInt32) fileSize {
	
	OSStatus ret = noErr;
	
	SInt64 fileSize = 0;
	UInt32 propSize = sizeof(fileSize);
	
	ret = ExtAudioFileGetProperty(self.audioFile, kExtAudioFileProperty_FileLengthFrames, &propSize, &fileSize);
	
	if (ret != noErr)
		return -1;
	
	return (UInt32)fileSize;
}

#pragma mark - Private

+ (ExtAudioFileRef) openAudioFileAtURL:(NSURL *)url withASBD:(AudioStreamBasicDescription)asbd {
	
	OSStatus ret = noErr;
	
	ExtAudioFileRef extAudioFile;
	
	// Open the audio file
	CFURLRef cfURL = (__bridge CFURLRef _Nonnull)(url);
	
	ret = ExtAudioFileOpenURL(cfURL, &extAudioFile);
	
	if (ret != noErr) {
		
		return nil;
	}
	
	ret = ExtAudioFileSetProperty(extAudioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &asbd);
	
	if (ret != noErr) {
		
		return nil;
	}
	
	return extAudioFile;
}

/// Aggregates data in the audio file in concurrent batches
- (NSData *) aggregateAudioDataForRect:(CGRect)rect {
	
	UInt32 bufferFrameSize = CGRectGetHeight(rect) * self.framesPerBin;
	
	AudioBufferList *abl = AllocateABL(self.asbd, bufferFrameSize);

	[self readAudioDataForOffset:CGRectGetMinY(rect) numFrames:&bufferFrameSize toBuffer:abl];
	
	NSUInteger displayDataLength = sizeof(Float32) * CGRectGetHeight(rect);
	void *displayDataBuffer = calloc(sizeof(Float32), CGRectGetHeight(rect));
	NSData *displayData = [NSData dataWithBytesNoCopy:displayDataBuffer length:displayDataLength freeWhenDone:YES];
	
	[self aggregateABL:abl withNumFrames:bufferFrameSize inBuffer:displayDataBuffer];
	
	FreeABL(abl);
	
	return displayData;
}

/// Reads audio data for the tile at origin and reduces the data for visual display by averaging samples into bins
- (void) readAudioDataForOffset:(CGFloat)offset numFrames:(UInt32 *)numFrames toBuffer:(AudioBufferList *)abl {
	
	dispatch_sync(self.audioFileQueue, ^{
		
		if (!self.audioFile)
			return;
		
		OSStatus ret = noErr;
		
		// Move the read head to the correct offset for the provided origin
		SInt64 offsetFrame = (SInt64)(offset * self.framesPerBin);
		ret = ExtAudioFileSeek(self.audioFile, offsetFrame);
		
		if (ret != noErr) {
			
			assert(@"Could not seek to offset");
			return;
		}
		
		// Read audio from file
		ret = ExtAudioFileRead(self.audioFile, numFrames, abl);
		
		if (ret != noErr) {
			
			assert(@"Failed to set audio client format");
			return;
		}
	});
}

- (void) aggregateABL:(AudioBufferList *)abl withNumFrames:(UInt32)framesRead inBuffer:(Float32 *)aggregateBuffer {
	
	// Initialize variables for average calculation
	Float64 totalAmplitude = 0;
	
	// Determine the number of bins contained in buffer
	UInt32 numBins = framesRead / self.framesPerBin;
	
	// Calculate each bin
	for(UInt32 bin = 0; bin < numBins; bin++){
		
		// Calculate an average by summing the amplitudes together and dividing by the number of samples
		
		// reset totalAmplitude to 0 for each bin
		totalAmplitude = 0;
		
		// Interate through each sample in the bin, adding the highest amplitude to the total
		for(UInt32 frame = 0; frame < self.framesPerBin; frame++) {
			
			Float32 amplitude = 0;

			// Loop through all buffers, if audio data is interleaved there will only be 1 buffer
			UInt32 numBuffers = abl->mNumberBuffers;
			for(UInt32 b = 0; b < numBuffers; b++) {
				
				// Get a reference to the buffer
				AudioBuffer *buffer = abl->mBuffers + b;
				
				// Cast the data buffer assuming, requiring Float32 here
				//TODO: choose a data type based on kAudioFormatFlags_kAudioFormatFlagIsFloat and mBytesPerFrame
				Float32 *data = (Float32 *)buffer->mData;
				
				// Loop through channels in the buffer, if data is noninterleaved there will only be 1 channel
				UInt32 numChannels = buffer->mNumberChannels;
				for(UInt32 channel = 0; channel < numChannels; channel++) {
					
					// calculate the samples offset in the buffer based on bin, frame, and channel
					UInt32 offset = (bin * self.framesPerBin) + (frame * numChannels) + channel;
					
					// take the highest of the two values, the new sample or the current max
					amplitude = MAX(amplitude,fabs(data[offset]));
				}
			}
			
			// add the amplitude to the bin total
			totalAmplitude += amplitude;
		}
		
		// Get bin value by getting the average amplitude
		Float32 binValue = totalAmplitude / self.framesPerBin;
		
		// Get a pointer to the bin
		Float32 *displayDataPtr = aggregateBuffer;
		displayDataPtr += (int)bin;
		
		// Set the bin
		*displayDataPtr = binValue;
	}
}

@end