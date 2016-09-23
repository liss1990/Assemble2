//
//  AppDelegate.m
//  Assemble
//
//  Created by 李丝思 on 16/9/22.
//  Copyright © 2016年 思. All rights reserved.
//

#import "AppDelegate.h"
#import "UMSocial.h"
#import "UMSocialWechatHandler.h"
#import "UMSocialSinaSSOHandler.h"
#import "WXApi.h"
#import <AlipaySDK/AlipaySDK.h>
@interface AppDelegate ()<WXApiDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self UMen];
    [self weixinPay];

    return YES;
}
-(void)weixinPay
{
   [WXApi registerApp:@"wxb4ba3c02aa476ea1" withDescription:@"WeChatPay"];

}

/**
 微信的回调
 */
- (void)onResp:(BaseResp *)resp {
    
    if ([resp isKindOfClass:[PayResp class]]) {
        
        NSString *stringMessage = @"支付结果";
        NSString *stringTitle  = @"支付结果";
        
        switch (resp.errCode) {
            case WXSuccess:
                
                stringMessage = @"支付结果: 成功!";
                
                NSLog(@"支付成功 - PaySuccess, retCode = %d", resp.errCode);
                
                break;
            default:
                
                stringMessage = [NSString stringWithFormat:@"支付结果: 失败!, retcode = %d, retstr = %@", resp.errCode, resp.errStr];
                
                break;
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:stringTitle
                                                            message:stringMessage
                                                           delegate:nil
                                                  cancelButtonTitle:@"好的"
                                                  otherButtonTitles:nil, nil];
        
        [alertView show];
    }
}

- (BOOL)application:(UIApplication *)application
      handleOpenURL:(NSURL *)url {
    
    return [WXApi handleOpenURL:url delegate:self];
}


-(void)UMen
{
     [UMSocialData setAppKey:@"57e3fba167e58e66fe004b55"];
//      [UMSocialWechatHandler setWXAppId:@"wxd930ea5d5a258f4f" appSecret:@"db426a9829e4b49a0dcac7b4162da6b6" url:@"http://www.umeng.com/social"];//微信
    //新浪
    [UMSocialSinaSSOHandler openNewSinaSSOWithAppKey:@"2963381856"
                                              secret:@"06bb372be2f38664bbd99431fd23f173"
                                         RedirectURL:@"http://www.baidu.com"];

}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    
    BOOL result = [UMSocialSnsService handleOpenURL:url];
    if (result == FALSE) {
        //调用其他SDK，例如支付宝SDK等
        if ([url.host isEqualToString:@"safepay"]) {
            
            // 支付跳转支付宝钱包进行支付，处理支付结果
            [[AlipaySDK defaultService] processOrderWithPaymentResult:url
                                                      standbyCallback:^(NSDictionary *resultDic) {
                                                          NSLog(@"result = %@",resultDic);
                                                      }];
            
            // 授权跳转支付宝钱包进行支付，处理支付结果
            [[AlipaySDK defaultService] processAuth_V2Result:url
                                             standbyCallback:^(NSDictionary *resultDic) {
                                                 
                                                 NSLog(@"result = %@",resultDic);
                                                 
                                                 // 解析 auth code
                                                 NSString *result = resultDic[@"result"];
                                                 NSString *authCode = nil;
                                                 
                                                 if (result.length > 0) {
                                                     
                                                     NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                                                     
                                                     for (NSString *subResult in resultArr) {
                                                         
                                                         if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                                                             
                                                             authCode = [subResult substringFromIndex:10];
                                                             
                                                             break;
                                                         }
                                                     }
                                                 }
                                                 NSLog(@"授权结果 authCode = %@", authCode?:@"");
                                             }];
        }else{

            return [WXApi handleOpenURL:url delegate:self];
        }
    }
        return result;
    
}

// NOTE: 9.0以后使用新API接口
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString*, id> *)options {
        if ([url.host isEqualToString:@"safepay"]) {
            
            // 支付跳转支付宝钱包进行支付，处理支付结果
            [[AlipaySDK defaultService] processOrderWithPaymentResult:url
                                                      standbyCallback:^(NSDictionary *resultDic) {
                                                          NSLog(@"result = %@",resultDic);
                                                      }];
            
            // 授权跳转支付宝钱包进行支付，处理支付结果
            [[AlipaySDK defaultService] processAuth_V2Result:url
                                             standbyCallback:^(NSDictionary *resultDic) {
                                                 
                                                 NSLog(@"result = %@",resultDic);
                                                 
                                                 // 解析 auth code
                                                 NSString *result = resultDic[@"result"];
                                                 NSString *authCode = nil;
                                                 
                                                 if (result.length > 0) {
                                                     
                                                     NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                                                     
                                                     for (NSString *subResult in resultArr) {
                                                         
                                                         if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                                                             
                                                             authCode = [subResult substringFromIndex:10];
                                                             
                                                             break;
                                                         }
                                                     }
                                                 }
                                                 NSLog(@"授权结果 authCode = %@", authCode?:@"");
                                             }];
        }if ([url.host isEqualToString:@"pay"]) {//微信支付
             return [WXApi handleOpenURL:url delegate:self];
        }else{
            return  [UMSocialSnsService handleOpenURL:url];
        } 
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
