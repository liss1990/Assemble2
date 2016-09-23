//
//  ViewController.m
//  Assemble
//
//  Created by 李丝思 on 16/9/22.
//  Copyright © 2016年 思. All rights reserved.
//

#import "ViewController.h"
#import "UMSocialControllerService.h"
#import "UMSocialSnsPlatformManager.h"
#import "UMSocialAccountManager.h"
#import "WXApi.h"
#import "DataSigner.h"
#import "AliPayOther.h"
#import "AliPayBizContent.h"
#import <AlipaySDK/AlipaySDK.h>

#import "UPPaymentControl.h"

@interface ViewController () <UIAlertViewDelegate, NSURLConnectionDelegate>

@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) NSMutableData *responseData;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)login:(id)sender {
    UIAlertController *alertController = [[UIAlertController alloc]init];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"微信" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction *action) {
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"新浪" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction *action) {
        // 点击按钮后的方法直接在这里面写
        [self xinlanglogin];
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}
-(void)weixinlogin
{
    
}

-(void)xinlanglogin
{
    UMSocialSnsPlatform *snsPlatform = [UMSocialSnsPlatformManager getSocialPlatformWithName:UMShareToSina];
    
    snsPlatform.loginClickHandler(self,[UMSocialControllerService defaultControllerService],YES,^(UMSocialResponseEntity *response){
        
        //          获取微博用户名、uid、token等
        
        if (response.responseCode == UMSResponseCodeSuccess) {
            
            NSDictionary *dict = [UMSocialAccountManager socialAccountDictionary];
            UMSocialAccountEntity *snsAccount = [[UMSocialAccountManager socialAccountDictionary] valueForKey:snsPlatform.platformName];
            NSLog(@"\nusername = %@,\n usid = %@,\n token = %@ iconUrl = %@,\n unionId = %@,\n thirdPlatformUserProfile = %@,\n thirdPlatformResponse = %@ \n, message = %@",snsAccount.userName,snsAccount.usid,snsAccount.accessToken,snsAccount.iconURL, snsAccount.unionId, response.thirdPlatformUserProfile, response.thirdPlatformResponse, response.message);
            
        }});


}

/**
 微信支付
 
 */
- (IBAction)weinPay:(id)sender {
    NSString *urlString = @"http://wxpay.weixin.qq.com/pub_v2/app/app_pay.php?plat=ios";
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                               
                               if (data != nil) {
                                   
                                   NSError *error;
                                   NSMutableDictionary *dictionart = NULL;
                                   
                                   dictionart = [NSJSONSerialization JSONObjectWithData:data
                                                                                options:NSJSONReadingMutableLeaves
                                                                                  error:&error];
                                   
                                   NSLog(@"URL: %@", urlString);
                                   
                                   if (dictionart != nil) {
                                       
                                       NSMutableString *retCode = [dictionart objectForKey:@"retcode"];
                                       
                                       if (retCode.integerValue == 0) {
                                           
                                           NSMutableString *stamp = [dictionart objectForKey:@"timestamp"];
                                           
                                           // 调起微信支付
                                           PayReq *req   = [[PayReq alloc] init];
                                           req.partnerId = [dictionart objectForKey:@"partnerid"];
                                           req.prepayId  = [dictionart objectForKey:@"prepayid"];
                                           req.nonceStr  = [dictionart objectForKey:@"noncestr"];
                                           req.timeStamp = stamp.intValue;
                                           req.package   = [dictionart objectForKey:@"package"];
                                           req.sign      = [dictionart objectForKey:@"sign"];
                                           
                                           [WXApi sendReq:req];
                                           
                                           // 日志输出
                                           NSLog(@"appid = %@", [dictionart objectForKey:@"appid"]);
                                           NSLog(@"partnerId = %@", req.partnerId);
                                           NSLog(@"prepayId = %@", req.prepayId);
                                           NSLog(@"nonceStr = %@", req.nonceStr);
                                           NSLog(@"timeStamp = %d", req.timeStamp);
                                           NSLog(@"package = %@", req.package);
                                           NSLog(@"sign = %@", req.sign);
                                           
                                       } else {
                                           
                                           NSLog(@"retmsg: %@", [dictionart objectForKey:@"retmsg"]);
                                       }
                                   } else {
                                       
                                       NSLog(@"服务器返回错误, 未获取到JSON对象");
                                   }
                               } else {
                                   
                                   NSLog(@"服务器返回错误");
                               }
                           }];
    
    
}

- (IBAction)zhifubaoPay:(id)sender {
    
    //重要说明
    //这里只是为了方便直接向商户展示支付宝的整个支付流程；所以Demo中加签过程直接放在客户端完成；
    //真实App里，privateKey等数据严禁放在客户端，加签过程务必要放在服务端完成；
    //防止商户私密数据泄露，造成不必要的资金损失，及面临各种安全风险；
    /*============================================================================*/
    /*=======================需要填写商户app申请的===================================*/
    /*============================================================================*/
    NSString *appID = @"";
    NSString *privateKey = @"";
    /*============================================================================*/
    /*============================================================================*/
    /*============================================================================*/
    
    //partner和seller获取失败,提示
    if ([appID length] == 0 || [privateKey length] == 0) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"缺少appId或者私钥。"
                                                       delegate:self
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    /*
     *生成订单信息及签名
     */
    //将商品信息赋予AlixPayOrder的成员变量
    AliPayOther *order = [AliPayOther new];
    
    // NOTE: app_id设置
    order.app_id = appID;
    
    // NOTE: 支付接口名称
    order.method = @"alipay.trade.app.pay";
    
    // NOTE: 参数编码格式
    order.charset = @"utf-8";
    
    // NOTE: 当前时间点
    NSDateFormatter* formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    order.timestamp = [formatter stringFromDate:[NSDate date]];
    
    // NOTE: 支付版本
    order.version = @"1.0";
    
    // NOTE: sign_type设置
    order.sign_type = @"RSA";
    
    // NOTE: 商品数据
    AliPayBizContent *biz_content = [AliPayBizContent new];
    biz_content.body = @"我是测试数据";
    biz_content.subject = @"1";
    biz_content.out_trade_no = [self generateTradeNO]; //订单ID（由商家自行制定）
    biz_content.timeout_express = @"30m"; //超时时间设置
    biz_content.total_amount = [NSString stringWithFormat:@"%.2f", 0.01]; //商品价格
    
    //将商品信息拼接成字符串
    NSString *orderInfo = [order orderInfoEncoded:NO];
    NSString *orderInfoEncoded = [order orderInfoEncoded:YES];
    
    NSLog(@"orderSpec = %@",orderInfo);
    
    // NOTE: 获取私钥并将商户信息签名，外部商户的加签过程请务必放在服务端，防止公私钥数据泄露；
    //       需要遵循RSA签名规范，并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(privateKey);
    
    NSString *signedString = [signer signString:orderInfo];
    
    // NOTE: 如果加签成功，则继续执行支付
    if (signedString != nil) {
        
        //应用注册scheme,在AliSDKDemo-Info.plist定义URL types
        NSString *appScheme = @"AliPay-Objective-C";
        
        // NOTE: 将签名成功字符串格式化为订单字符串,请严格按照该格式
        NSString *orderString = [NSString stringWithFormat:@"%@&sign=%@",
                                 orderInfoEncoded, signedString];
        
        // NOTE: 调用支付结果开始支付
        [[AlipaySDK defaultService] payOrder:orderString
                                  fromScheme:appScheme
                                    callback:^(NSDictionary *resultDic) {
                                        NSLog(@"reslut = %@",resultDic);
                                    }];
    }

    
    
    
}
- (NSString *)generateTradeNO {
    
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    
    srand((unsigned)time(0));
    
    for (int i = 0; i < kNumber; i++) {
        
        unsigned index = rand() % [sourceStr length];
        
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        
        [resultStr appendString:oneStr];
    }
    
    return resultStr;
}
- (IBAction)bankPay:(id)sender {
    [self startNetWithURL:[NSURL URLWithString:@"http://101.231.204.84:8091/sim/getacptn"]];

    
}

- (void)startNetWithURL:(NSURL *)url {
    
    [self showAlertWait];
    
    NSURLRequest *urlRequest=[NSURLRequest requestWithURL:url];
    
    NSURLConnection *urlConn = [[NSURLConnection alloc] initWithRequest:urlRequest
                                                               delegate:self];
    
    [urlConn start];
}

- (void)showAlertWait {
    
    [self hideAlert];
    
    _alertView = [[UIAlertView alloc] initWithTitle:@"正在获取TN,请稍后..."
                                            message:@""
                                           delegate:self
                                  cancelButtonTitle:nil
                                  otherButtonTitles:nil, nil];
    [_alertView show];
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    activityIndicatorView.center = CGPointMake(_alertView.frame.size.width / 2.0f - 15,
                                               _alertView.frame.size.height / 2.0f + 10);
    
    [activityIndicatorView startAnimating];
    
    [_alertView addSubview:activityIndicatorView];
}

- (void)hideAlert {
    
    if (_alertView != nil) {
        
        [_alertView dismissWithClickedButtonIndex:0
                                         animated:NO];
        
        _alertView = nil;
    }
}

- (void)showAlertMessage:(NSString *)message {
    
    [self hideAlert];
    
    _alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                            message:message
                                           delegate:self
                                  cancelButtonTitle:@"确定"
                                  otherButtonTitles:nil, nil];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    _alertView = nil;
}

#pragma mark - connection
- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response {
    
    NSHTTPURLResponse *rsp = (NSHTTPURLResponse*)response;
    
    NSInteger code = [rsp statusCode];
    
    NSLog(@"Code: %zd", code);
    
    if (code != 200) {
        
        [self showAlertMessage:@"网络错误"];
        [connection cancel];
        
    } else {
        
        _responseData = [[NSMutableData alloc] init];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    [self hideAlert];
    
    NSString *tn = [[NSMutableString alloc] initWithData:_responseData
                                                encoding:NSUTF8StringEncoding];
    
    if (tn != nil && tn.length > 0) {
        
        NSLog(@"TN: %@",tn);
        
        [[UPPaymentControl defaultControl] startPay:tn
                                         fromScheme:@"UnionPay-Objective-C"
                                               mode:@"01"
                                     viewController:self];
    }
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error {
    
    [self showAlertMessage:@"网络错误"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
