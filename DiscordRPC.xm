// DiscordRPC.xm
#import <Foundation/Foundation.h>
#import <os/log.h>
#import "Headers/YTPlayerViewController.h"

static NSString *SERVER_URL = @"http://192.168.3.100:5000";
static os_log_t rpcLog;

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
        if (e) os_log_error(rpcLog, "送信失敗: %{public}@", e.localizedDescription);
        else   os_log(rpcLog, "送信成功: %{public}@ / %{public}@", title, ytmURL);
    }] resume];
}

static void sendStop(void) {
    NSURL *url = [NSURL URLWithString:[SERVER_URL stringByAppendingString:@"/stop"]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{} options:0 error:nil];
    [[NSURLSession.sharedSession dataTaskWithRequest:req completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        if (e) os_log_error(rpcLog, "停止通知失敗: %{public}@", e.localizedDescription);
        else   os_log(rpcLog, "停止通知成功");
    }] resume];
}

%ctor {
    rpcLog = os_log_create("com.discordrpc", "main");
    os_log(rpcLog, "[DiscordRPC] tweak loaded!");
}

%hook YTPlayerViewController

- (void)playbackController:(id)arg1 didActivateVideo:(id)arg2 withPlaybackData:(id)arg3 {
    %orig;

    NSString *videoID = self.currentVideoID;
    NSString *title   = nil;
    NSString *artist  = nil;

    @try {
        id playerResponse = [self valueForKey:@"playerResponse"];
        id videoDetails   = [playerResponse valueForKey:@"videoDetails"];
        title  = [videoDetails valueForKey:@"title"];
        artist = [videoDetails valueForKey:@"author"];
        if (!title)  title  = [videoDetails valueForKey:@"videoTitle"];
        if (!artist) artist = [videoDetails valueForKey:@"channelName"];
    } @catch (NSException *e) {
        os_log_error(rpcLog, "曲情報取得失敗: %{public}@", e);
    }

    os_log(rpcLog, "[DiscordRPC] 再生: %{public}@ / %{public}@ / %{public}@", title, artist, videoID);
    sendPlay(videoID, title, artist);
}

- (void)playbackController:(id)arg1 didDeactivateVideo:(id)arg2 {
    %orig;
    os_log(rpcLog, "[DiscordRPC] 停止");
    sendStop();
}

%end
