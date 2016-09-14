//
//  AudioBufferListHelpers.h
//  AudioUIKit
//
//  Created by Adam Ritenauer on 9/10/16.
//  Copyright © 2016 Adam Ritenauer. All rights reserved.
//

#ifndef AudioBufferListHelpers_h
#define AudioBufferListHelpers_h

#include <stdio.h>
#import <AudioToolbox/AudioToolbox.h>

AudioBufferList * AllocateABL(AudioStreamBasicDescription asbd, UInt32 capacityFrames);
void FreeABL(AudioBufferList *abl);

#endif /* AudioBufferListHelpers_h */
