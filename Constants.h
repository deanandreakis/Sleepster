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

#define FLURRY_KEY @"D34VV6Z525ZTGNRCJXWC"

#define CRASHLYTICS_KEY @"2eaad7ad1fecfce6c414905676a8175bb2a1c253"

#define MIN_NUM_BG_OBJECTS 50
#define NUM_PERMANENT_BG_OBJECTS 21

#define RESTORATION_ID_MAIN_VC @"MainViewControllerID"
#define RESTORATION_ID_INFO_VC @"InformationViewControllerID"
#define RESTORATION_ID_SETTINGS_VC @"SettingsViewControllerID"
#define RESTORATION_ID_SOUNDS_VC @"SoundsViewControllerID"
#define RESTORATION_ID_BG_VC @"BackgroundsViewControllerID"
#define RESTORATION_ID_TAB_BAR_C @"UITabBarControllerID"
#define RESTORATION_ID_BACKLIGHT_VC @"BacklightViewControllerID"
#define RESTORATION_ID_TIMER_VC @"TimerViewControllerID"

#define STOREKIT_PRODUCT_ID_BACKGROUNDS @"multiplebg"
#define STOREKIT_PRODUCT_ID_SOUNDS @"multiplesounds"

#endif
