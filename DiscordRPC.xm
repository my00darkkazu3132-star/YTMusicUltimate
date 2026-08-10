// DiscordRPC.xm
#import <Foundation/Foundation.h>
#import "Headers/YTPlayerViewController.h"

static NSString *SERVER_URL = @"http://192.168.3.100:5000";

static void sendPlay(NSString *videoID, NSString *title, NSString *artist) {
    if (!videoID || videoID.length == 0) return;
    NSString *ytmURL = [NSString stringWithFormat:@"https://music.youtube.com/watch?v=%@", videoID];
    NSURL *url = [NSURL URLWithString:[SERVER_URL stringByAppendingString:@"/play"]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    body[@"url"] = ytmURL;
    if (title)  body[@"title"]  = title;
    if (artist) body[@"artist"] = artist;

    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [[NSURLSession.sharedSession dataTaskWithRequest:req completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        if (e) NSLog(@"[DiscordRPC] 送信失敗: %@", e.localizedDescription);
        else   NSLog(@"[DiscordRPC] 送信成功: %@ / %@ / %@", title, artist, ytmURL);
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

%hook YTPlayerViewController

- (void)playbackController:(id)arg1 didActivateVideo:(id)arg2 withPlaybackData:(id)arg3 {
    %orig;

    NSString *videoID = self.currentVideoID;
    NSString *title   = nil;
    NSString *artist  = nil;

    @try {
        // playerResponse → videoDetails からタイトル・作者を取得
        id playerResponse = [self valueForKey:@"playerResponse"];
        id videoDetails   = [playerResponse valueForKey:@"videoDetails"];
        title  = [videoDetails valueForKey:@"title"];
        artist = [videoDetails valueForKey:@"author"];

        // 取れなければ別のキーも試す
        if (!title)  title  = [videoDetails valueForKey:@"videoTitle"];
        if (!artist) artist = [videoDetails valueForKey:@"channelName"];
    } @catch (NSException *e) {
        NSLog(@"[DiscordRPC] 曲情報取得失敗: %@", e);
    }

    NSLog(@"[DiscordRPC] 再生: %@ / %@ / %@", title, artist, videoID);
    sendPlay(videoID, title, artist);
}

- (void)playbackController:(id)arg1 didDeactivateVideo:(id)arg2 {
    %orig;
    NSLog(@"[DiscordRPC] 停止");
    sendStop();
}

%end
