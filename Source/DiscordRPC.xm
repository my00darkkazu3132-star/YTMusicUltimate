// DiscordRPC.xm
#import <Foundation/Foundation.h>
#import "Headers/YTPlayerViewController.h"

static NSString *SERVER_URL = @"http://192.168.3.100:5000";

static void sendPlayURL(NSString *videoID) {
    if (!videoID || videoID.length == 0) return;
    NSString *ytmURL = [NSString stringWithFormat:@"https://music.youtube.com/watch?v=%@", videoID];
    NSURL *url = [NSURL URLWithString:[SERVER_URL stringByAppendingString:@"/play"]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"url": ytmURL} options:0 error:nil];
    [[NSURLSession.sharedSession dataTaskWithRequest:req completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        if (e) NSLog(@"[DiscordRPC] 送信失敗: %@", e.localizedDescription);
        else   NSLog(@"[DiscordRPC] 送信成功: %@", ytmURL);
    }] resume];
}

static void sendStop(void) {
    NSURL *url = [NSURL URLWithString:[SERVER_URL stringByAppendingString:@"/stop"]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{} options:0 error:nil];
    [[NSURLSession.sharedSession dataTaskWithRequest:req completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        if (e) NSLog(@"[DiscordRPC] 停止通知失敗: %@", e.localizedDescription);
        else   NSLog(@"[DiscordRPC] 停止通知成功");
    }] resume];
}

// SponsorBlock.xと同じクラス・メソッドを使う
%hook YTPlayerViewController

// 曲が変わったときに呼ばれる
- (void)playbackController:(id)arg1 didActivateVideo:(id)arg2 withPlaybackData:(id)arg3 {
    %orig;
    NSLog(@"[DiscordRPC] didActivateVideo 呼ばれた! videoID: %@", self.currentVideoID);
    sendPlayURL(self.currentVideoID);
}

// 一時停止・停止のタイミング
- (void)playbackController:(id)arg1 didDeactivateVideo:(id)arg2 {
    %orig;
    NSLog(@"[DiscordRPC] didDeactivateVideo 呼ばれた!");
    sendStop();
}

// 一時停止・再開を検知
- (void)playbackController:(id)arg1 didChangeToPlaybackState:(int)state {
    %orig;
    NSLog(@"[DiscordRPC] playbackState: %d", state);
    // state: 1=バッファ中, 2=再生中, 3=一時停止, 5=終了
    if (state == 3 || state == 5) {
        sendStop();
    } else if (state == 2) {
        sendPlayURL(self.currentVideoID);
    }
}

%end
