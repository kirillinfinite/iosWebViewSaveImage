//
//  ViewController.m
//  SaveImageExample
//
//  Created by Kirill Chatrov on 2016-10-04.
//  Copyright © 2016 Kirill Chatrov. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *urlString = @"i1.theportalwiki.net/img/thumb/7/79/GLaDOS_P2.png/400px-GLaDOS_P2.png";
    
    self.url = [self cleanURL:[NSURL URLWithString:urlString]];
    
    self.webView.delegate = self;
    
    [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:self.url]];
}


#pragma mark - private methods
- (NSURL *)cleanURL:(NSURL *)url
{
    //If no URL scheme was supplied, defer back to HTTP.
    if (url.scheme.length == 0) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", [url absoluteString]]];
    }
    
    return url;
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"start load");
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"finish load");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"load fail");
    
}

@end
