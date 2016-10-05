#import "ViewController.h"

@interface ViewController (ImageHelper)<UIWebViewDelegate, UIGestureRecognizerDelegate>

/**
 * Get image URL from JS
 */
@property (nonatomic, strong) NSString *imageJS;


/**
 * Image
 */
@property (strong, nonatomic) UIImage *image;

@end
