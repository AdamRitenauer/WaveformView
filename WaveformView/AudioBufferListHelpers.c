//
//  AudioBufferListHelpers.c
//  AudioUIKit
//
//  Created by Adam Ritenauer on 9/10/16.
//  Copyright © 2016 Adam Ritenauer. All rights reserved.
//

#include "AudioBufferListHelpers.h"

AudioBufferList * AllocateABL(AudioStreamBasicDescription asbd, UInt32 capacityFrames)
{
	AudioBufferList *bufferList = NULL;
	
	bool interleaved = (asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved) == 0;
	
	UInt32 numBuffers = interleaved ? 1 : asbd.mChannelsPerFrame;
	UInt32 channelsPerBuffer = interleaved ? asbd.mChannelsPerFrame : 1;
	
	void *ablMemory = calloc(1, offsetof(AudioBufferList, mBuffers) + (sizeof(AudioBuffer) * numBuffers));
	if (ablMemory == NULL)
		return nil;
	
	bufferList = (AudioBufferList *)ablMemory;
	
	bufferList->mNumberBuffers = numBuffers;
	
	for(UInt32 bufferIndex = 0; bufferIndex < bufferList->mNumberBuffers; ++bufferIndex) {
		
		void *dataBuffer = calloc(capacityFrames, asbd.mBytesPerFrame);
		
		if (dataBuffer == NULL)
			return nil;
		
		bufferList->mBuffers[bufferIndex].mData = dataBuffer;
		bufferList->mBuffers[bufferIndex].mDataByteSize = capacityFrames * asbd.mBytesPerFrame;
		bufferList->mBuffers[bufferIndex].mNumberChannels = channelsPerBuffer;
	}
	
	return bufferList;
}

void FreeABL(AudioBufferList *abl) {
	
	// Free all buffers in the list
	for (UInt32 b = 0; b < abl->mNumberBuffers; b++) {
		
		AudioBuffer buffer = abl->mBuffers[b];
		
		free(buffer.mData);
	}
	
	// Free the audio buffer list
	free(abl);
}