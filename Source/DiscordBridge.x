#import <Foundation/Foundation.h>

%hook YTPlayerViewController

- (NSString *)currentVideoID {
    NSString *videoID = %orig;

    if (videoID) {
        NSLog(@"[DiscordBridge] currentVideoID = %@", videoID);
    }

    return videoID;
}

%end
