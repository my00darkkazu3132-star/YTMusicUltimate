// DiscordRPC.xm
// YTMusicUltimateに追加するtweak
// 再生中の曲URLをPCのFlaskサーバーに送信してChromeで開かせる

#import <Foundation/Foundation.h>

// ===== 設定：PCのIPアドレス =====
static NSString *SERVER_URL = @"http://192.168.3.100:5000";
// ================================


/// PCサーバーにYTMusic URLをPOSTする
static void sendPlayURL(NSString *videoID) {
    NSString *ytmURL = [NSString stringWithFormat:@"https://music.youtube.com/watch?v=%@", videoID];

    NSURL *url = [NSURL URLWithString:[SERVER_URL stringByAppendingString:@"/play"]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *body = @{@"url": ytmURL};
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];

    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:req completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        if (e) NSLog(@"[DiscordRPC] 送信失敗: %@", e.localizedDescription);
        else   NSLog(@"[DiscordRPC] 送信成功: %@", ytmURL);
    }] resume];
}

/// PCサーバーに停止を通知する
static void sendStop(void) {
    NSURL *url = [NSURL URLWithString:[SERVER_URL stringByAppendingString:@"/stop"]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{} options:0 error:nil];

    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:req completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        if (e) NSLog(@"[DiscordRPC] 停止通知失敗: %@", e.localizedDescription);
        else   NSLog(@"[DiscordRPC] 停止通知成功");
    }] resume];
}


// ===== YouTube Musicの再生状態をフック =====

%hook YTMNowPlayingViewController

/// 曲が切り替わったときに呼ばれる
- (void)updateContentForItem:(id)item {
    %orig;

    @try {
        // video IDを取得してURLを組み立てて送信
        NSString *videoID = [item valueForKey:@"videoId"];
        if (videoID && videoID.length > 0) {
            sendPlayURL(videoID);
        }
    } @catch (NSException *e) {
        NSLog(@"[DiscordRPC] updateContentForItem 例外: %@", e);
    }
}

/// 再生状態が変わったときに呼ばれる（一時停止など）
- (void)playerStateDidChange:(id)state {
    %orig;

    @try {
        // playbackState: 1=再生中 / 2=一時停止
        NSInteger playbackState = [[state valueForKey:@"playbackState"] integerValue];
        if (playbackState == 2) {
            sendStop();
        }
    } @catch (NSException *e) {
        NSLog(@"[DiscordRPC] playerStateDidChange 例外: %@", e);
    }
}

%end
