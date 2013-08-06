//
//  Constants.h
//  SleepMate
//
//  Created by Dean Andreakis on 5/18/13.
//
//

#ifndef SleepMate_Constants_h
#define SleepMate_Constants_h

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define FLICKR_API_KEY @"ab284ac09b04f83cf5af22e4bc3b6e56"
#define FLICKR_SECRET e2e0f5b8158b1f83

#define FLICKR_THUMBNAIL_SIZE 70

#define BG_STOREKIT_STATUS @"enable_multiple_bg_selection"
#define SOUND_STOREKIT_STATUS @"enable_sound_mixing"

#endif
