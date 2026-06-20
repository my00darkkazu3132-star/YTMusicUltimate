// DiscordRPC.xm - デバッグ版
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *SERVER_URL = @"http://192.168.3.100:5000";

static void sendPlayURL(NSString *videoID) {
    NSString *ytmURL = [NSString stringWithFormat:@"https://music.youtube.com/watch?v=%@", videoID];
    NSURL *url = [NSURL URLWithString:[SERVER_URL stringByAppendingString:@"/play"]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *body = @{@"url": ytmURL};
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
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

// ===== クラス名を総当たりで探す =====
// YTMusicのバージョンによってクラス名が変わるため、
// "NowPlaying" を含む全クラスをログに出力する
%ctor {
    NSLog(@"[DiscordRPC] tweak loaded!");

    // 全クラスからNowPlaying関連を探してログに出す
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    objc_getClassList(classes, numClasses);
    for (int i = 0; i < numClasses; i++) {
        NSString *name = NSStringFromClass(classes[i]);
        if ([name containsString:@"NowPlaying"] || [name containsString:@"nowPlaying"]) {
            NSLog(@"[DiscordRPC] クラス発見: %@", name);
        }
    }
    free(classes);
}

// とりあえず元のhookも残しておく
%hook YTMNowPlayingViewController

- (void)updateContentForItem:(id)item {
    %orig;
    NSLog(@"[DiscordRPC] updateContentForItem 呼ばれた!");
    @try {
        NSString *videoID = [item valueForKey:@"videoId"];
        if (videoID && videoID.length > 0) {
            sendPlayURL(videoID);
        }
    } @catch (NSException *e) {
        NSLog(@"[DiscordRPC] 例外: %@", e);
    }
}

- (void)playerStateDidChange:(id)state {
    %orig;
    NSLog(@"[DiscordRPC] playerStateDidChange 呼ばれた!");
    @try {
        NSInteger playbackState = [[state valueForKey:@"playbackState"] integerValue];
        if (playbackState == 2) {
            sendStop();
        }
    } @catch (NSException *e) {
        NSLog(@"[DiscordRPC] 例外: %@", e);
    }
}

%end
