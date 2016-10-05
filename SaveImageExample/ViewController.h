//
//  ViewController.h
//  SaveImageExample
//
//  Created by Kirill Chatrov on 2016-10-04.
//  Copyright © 2016 Kirill Chatrov. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) NSURL *url;

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end
