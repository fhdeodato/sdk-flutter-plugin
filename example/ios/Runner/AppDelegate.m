// AppDelegate.m
//
// Copyright (c) 2024 Salesforce, Inc
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer. Redistributions in binary
// form must reproduce the above copyright notice, this list of conditions and
// the following disclaimer in the documentation and/or other materials
// provided with the distribution. Neither the name of the nor the names of
// its contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <MarketingCloudSDK/MarketingCloudSDK.h>
#import <PushFeatureSDK/PushFeatureSDK.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    [self configureSdk];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)configureSdk {
    SFMarketingCloudSdkConfigBuilder *engagementConfigBuilder =
        [[SFMarketingCloudSdkConfigBuilder alloc] initWithAppId:@"{MC_APP_ID}"];
    [engagementConfigBuilder setAccessToken:@"{MC_ACCESS_TOKEN}"];
    [engagementConfigBuilder setMarketingCloudServerUrl:[NSURL URLWithString:@"{MC_APP_SERVER_URL}"]];
    [engagementConfigBuilder setMid:@"MC_MID"];
    [engagementConfigBuilder setAnalyticsEnabled:YES];
    [engagementConfigBuilder setInboxEnabled:YES];

    SFPushFeatureConfigBuilder *pushFeatureConfigBuilder = [[SFPushFeatureConfigBuilder alloc] init];
    SFPushFeatureConfig *pushFeatureConfig =
        [[pushFeatureConfigBuilder setApplicationControlsBadging:YES] build];

    SFMCSdkConfig *configuration = [[[[SFMCSdkConfigBuilder new]
        setEngagementWithConfig:[engagementConfigBuilder build]]
        setPushFeatureWithConfig:pushFeatureConfig] build];

    [SFMCSdk initializeSdk:configuration completion:^(NSArray<SFMCModuleInitStatus *> *status) {
        BOOL allSuccessful = YES;
        for (SFMCModuleInitStatus *moduleStatus in status) {
            if (moduleStatus.initStatus != SFMCSdkOperationResultSuccess) {
                allSuccessful = NO;
            }
        }
        if (allSuccessful) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self pushSetup];
            });
        } else {
            NSLog(@"SFMC sdk configuration failed.");
        }
    }];
}

- (void)pushSetup {
    [SFPushFeature requestSdk:^(id<SFPushFeatureApi> pushFeature) {
        [pushFeature setURLHandlingDelegate:self];
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
        [[UIApplication sharedApplication] registerForRemoteNotifications];

        [[UNUserNotificationCenter currentNotificationCenter]
         requestAuthorizationWithOptions:UNAuthorizationOptionAlert |
         UNAuthorizationOptionSound |
         UNAuthorizationOptionBadge
         completionHandler:^(BOOL granted, NSError *_Nullable error) {
            if (error == nil && granted == YES) {
                NSLog(@"User granted permission");
            }
        }];
    });
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [SFPushFeature requestSdk:^(id<SFPushFeatureApi> pushFeature) {
        [pushFeature setDeviceToken:deviceToken];
    }];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    os_log_debug(OS_LOG_DEFAULT, "didFailToRegisterForRemoteNotificationsWithError = %@", error);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    [SFPushFeature requestSdk:^(id<SFPushFeatureApi> pushFeature) {
        [pushFeature setNotificationResponse:response];
    }];
    if (completionHandler != nil) {
        completionHandler();
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [SFPushFeature requestSdk:^(id<SFPushFeatureApi> pushFeature) {
        [pushFeature setNotificationUserInfo:userInfo];
    }];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)sfmc_handleURL:(NSURL * _Nonnull)url type:(NSString * _Nonnull)type {
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"url %@ opened successfully", url);
            } else {
                NSLog(@"url %@ could not be opened", url);
            }
        }];
    }
}

@end
