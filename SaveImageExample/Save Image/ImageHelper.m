

#import "ImageHelper.h"
#import "SwizzleMethod.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, SelectItem) {
    SelectItemSaveImage,
};

#define iOS7_OR_EARLY ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)

//injected javascript
static NSString *const kTouchJavaScriptString =
@"document.ontouchstart=function(event){\
x=event.targetTouches[0].clientX;\
y=event.targetTouches[0].clientY;\
document.location=\"myweb:touch:start:\"+x+\":\"+y;};\
document.ontouchmove=function(event){\
x=event.targetTouches[0].clientX;\
y=event.targetTouches[0].clientY;\
document.location=\"myweb:touch:move:\"+x+\":\"+y;};\
document.ontouchcancel=function(event){\
document.location=\"myweb:touch:cancel\";};\
document.ontouchend=function(event){\
document.location=\"myweb:touch:end\";};";

static NSString *const kImageJS               = @"keyForImageJS";
static NSString *const kImage                 = @"keyForImage";

static const NSTimeInterval KLongGestureInterval = 0.8f;


@implementation ViewController (ImageHelper)

+(void)load
{
    [super load];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self hookWebView];
    });
}

+ (void)hookWebView
{
    SwizzlingMethod([self class], @selector(webViewDidStartLoad:), @selector(sl_webViewDidStartLoad:));
    SwizzlingMethod([self class], @selector(webView:shouldStartLoadWithRequest:navigationType:), @selector(sl_webView:shouldStartLoadWithRequest:navigationType:));
    SwizzlingMethod([self class], @selector(webViewDidFinishLoad:), @selector(sl_webViewDidFinishLoad:));
}

#pragma mark - seter and getter

- (void)setImageJS:(NSString *)imageJS
{
    objc_setAssociatedObject(self, &kImageJS, imageJS, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)imageJS
{
    return objc_getAssociatedObject(self, &kImageJS);
}


- (void)setImage:(UIImage *)image
{
    objc_setAssociatedObject(self, &kImage, image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)image
{
    return objc_getAssociatedObject(self, &kImage);
}

#pragma mark - Save image callback
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *message = @"Succeed";
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image"
//                                                    message:@"Your image is now saved to your Photo Library"
//                                                   delegate:self
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//  ** DEPRECATED in iOS9+
    
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Success"
                                  message:@"Your image is now saved to your Photo Library"
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
    
    if (error) {
        message = @"Fail";
    }
    NSLog(@"save result :%@", message);
}


#pragma mark - swizzling

- (BOOL)sl_webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *requestString = [[request URL] absoluteString];
    
    NSArray *components = [requestString componentsSeparatedByString:@":"];
    
    if ([components count] > 1 && [(NSString *)[components objectAtIndex:0] isEqualToString:@"myweb"]) {
        
        if([(NSString *)[components objectAtIndex:1] isEqualToString:@"touch"]) {
            
            if ([(NSString *)[components objectAtIndex:2] isEqualToString:@"start"]) {
                
                //NSLog(@"touch start!");
                
                float pointX = [[components objectAtIndex:3] floatValue];
                float pointY = [[components objectAtIndex:4] floatValue];
                
                NSLog(@"touch point (%f, %f)", pointX, pointY);
                
                NSString *js = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).tagName", pointX, pointY];
                
                NSString * tagName = [self.webView stringByEvaluatingJavaScriptFromString:js];
                
                self.imageJS = nil;
                if ([tagName isEqualToString:@"IMG"]) {
                    
                    self.imageJS = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", pointX, pointY];
                    
                }
                
            } else {
                
                if ([(NSString *)[components objectAtIndex:2] isEqualToString:@"move"]) {
                    // NSLog(@"move");
                } else {
                    if ([(NSString *)[components objectAtIndex:2] isEqualToString:@"end"]) {
                        // NSLog(@"touch end");
                    }
                }
            }
        }
        
        if (self.imageJS) {
            //    NSLog(@"touching image");
        }
        
        return NO;
    }
    
    return [self sl_webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
}

- (void)sl_webViewDidStartLoad:(UIWebView *)webView
{
    //Add long press gresture for web view
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = KLongGestureInterval;
    longPress.delegate = self;
    [self.webView addGestureRecognizer:longPress];
    
    [self sl_webViewDidStartLoad:webView];
}

- (void)sl_webViewDidFinishLoad:(UIWebView *)webView
{
    //cache manager
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
    
    //inject js
    [webView stringByEvaluatingJavaScriptFromString:kTouchJavaScriptString];
    
    [self sl_webViewDidFinishLoad:webView];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
        return NO;
    
    if ([self isTouchingImage]) {
        if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            otherGestureRecognizer.enabled = NO;
            otherGestureRecognizer.enabled = YES;
        }
        
        return YES;
    }
    
    return NO;
}

#pragma mark - private Method
- (BOOL)isTouchingImage
{
    if (self.imageJS) {
        return YES;
    }
    return NO;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    NSString *imageUrl = [self.webView stringByEvaluatingJavaScriptFromString:self.imageJS];
    
    if (imageUrl) {
        
        NSData *data = nil;

        data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        
        UIImage *image = [UIImage imageWithData:data];
        if (!image) {
            // NSLog(@"read fail");
            return;
        }
        self.image = image;
        
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Save image"
                                                                       message:@"Your image will be saved to your Photo Album"
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Save Image" style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
                                                            UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                                                        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
        }];
        
        [alert addAction:ok];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    
}


@end
