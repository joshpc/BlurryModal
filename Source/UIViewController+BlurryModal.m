//
//  UIViewController+BlurryModal.m
//  BlurryModal
//
//  Created by Joshua Tessier on 2013-09-24.
//  Copyright (c) 2013 Joshua Tessier. All rights reserved.
//

#import "UIViewController+BlurryModal.h"

#define kJTBlurRadius 15.0f
#define kJTBlurAnimationDuration 0.5f

/**
 * Simple class to manage the modal views that are displayed. This is class is not thread safe.
 */
@interface JTModalManager : NSObject

@property (nonatomic, strong) NSMutableArray *viewControllerStack;
@property (nonatomic, strong) NSMutableArray *blurryOverlayStack;

@end

static void callCompletionBlock(JTCompletionBlock completion) {
	if (completion) {
		completion();
	}
}

@interface UIView (Snapshot)
- (UIImageView*)blurryImageOverlayWithAlpha:(CGFloat)alpha;
@end

static JTModalManager *_modalManager;

@implementation UIViewController (JTModal)

+ (void)initialize
{
	if ([self class] == [UIViewController class]) {
		_modalManager = [[JTModalManager alloc] init];
	}
}

#pragma mark - Push Modal View Controller

+ (CGSize)preferredModalSizeForController:(UIViewController*)controller constrainedTo:(CGRect)bounds
{
	CGSize viewSize = bounds.size;
	UIViewController *rootController = controller;
	
	while ([rootController isKindOfClass:[UINavigationController class]]) {
		rootController = [[(UINavigationController*)rootController viewControllers] lastObject];
	}
	
	if ([rootController conformsToProtocol:@protocol(JTBlurryModal)] && [rootController respondsToSelector:@selector(sizeWhenPresentedModally)]) {
		viewSize = [(id<JTBlurryModal>)rootController sizeWhenPresentedModally];
	}
	
	return viewSize;
}

- (void)pushModalViewController:(UIViewController*)controller
{
	[self pushModalViewController:controller animated:NO];
}

- (void)pushModalViewController:(UIViewController*)controller animated:(BOOL)animated
{
	[self pushModalViewController:controller animated:animated completion:nil];
}

- (void)pushModalViewController:(UIViewController*)controller animated:(BOOL)animated completion:(void (^)(void))completion
{
	UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
	CGRect bounds = [keyWindow bounds];
	CGSize viewSize = [UIViewController preferredModalSizeForController:controller constrainedTo:bounds];
	
	CGFloat alpha = animated ? 0.0f : 1.0f;
	UIImageView *overlay = [keyWindow blurryImageOverlayWithAlpha:alpha];
	[keyWindow addSubview:overlay];
	[_modalManager.blurryOverlayStack addObject:overlay];
	
	UIView *view = controller.view;
	view.alpha = alpha;
	view.frame = CGRectMake(0.0f, 0.0f, viewSize.width, viewSize.height);
	
	UIView *containerView = [[UIView alloc] init];
	containerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
	containerView.backgroundColor = [UIColor clearColor];
	containerView.frame = CGRectMake(bounds.origin.x + roundf((bounds.size.width - viewSize.width) * 0.5f), bounds.origin.y + roundf((bounds.size.height - viewSize.height) * 0.5f), viewSize.width, viewSize.height);
	[containerView addSubview:view];
	
	[overlay addSubview:containerView];
	[self addChildViewController:controller];
	[_modalManager.viewControllerStack addObject:controller];
	[controller didMoveToParentViewController:self];
	
	[self completeTransition:controller overlay:overlay animated:animated completion:completion pushing:YES];
}

#pragma mark - Pop View Controller

- (void)popModalViewController
{
	[self popModalViewController:NO];
}

- (void)popModalViewController:(BOOL)animated
{
	[self popModalViewController:animated completion:nil];
}

- (void)popModalViewController:(BOOL)animated completion:(void (^)(void))completion
{
	if ([_modalManager.viewControllerStack count] > 0) {
		UIViewController *controller = [_modalManager.viewControllerStack lastObject];
		UIImageView *overlay = [_modalManager.blurryOverlayStack lastObject];
		[_modalManager.viewControllerStack removeObject:controller];
		[_modalManager.blurryOverlayStack removeObject:overlay];

		[controller willMoveToParentViewController:nil];
		[controller viewWillDisappear:animated];
		[controller.parentViewController completeTransition:controller overlay:overlay animated:animated completion:^{
			[overlay removeFromSuperview];
			[controller removeFromParentViewController];
			[controller viewDidDisappear:animated];
			
			completion();
		} pushing:NO];
	}
}

#pragma mark - Appearing and Disappearing

- (void)updateOverlay:(UIImageView*)overlay controller:(UIViewController*)controller pushing:(BOOL)isPushing
{
	self.view.alpha = isPushing ? 0.0f : 1.0f;
	self.view.frame = CGRectInset(self.view.frame, isPushing ? kJTBlurRadius : -kJTBlurRadius, isPushing ? kJTBlurRadius : -kJTBlurRadius);
	overlay.alpha = isPushing ? 1.0f : 0.0f;
	controller.view.alpha = isPushing ? 1.0f : 0.0f;
}

- (void)completeTransition:(UIViewController*)controller overlay:(UIImageView*)overlay animated:(BOOL)animated completion:(void (^)())completion pushing:(BOOL)isPushing
{
	if (animated) {
		[UIView animateWithDuration:kJTBlurAnimationDuration animations:^{
			[self updateOverlay:overlay controller:controller pushing:isPushing];
		} completion:^(BOOL finished) {
			callCompletionBlock(completion);
		}];
	}
	else {
		[self updateOverlay:overlay controller:controller pushing:isPushing];
		callCompletionBlock(completion);
	}
}

@end

@implementation UIView (Snapshot)

- (UIImage*)snapshot
{
	CGRect bounds = [self bounds];
	CGSize size = CGSizeMake(bounds.size.width - kJTBlurRadius * 2.0f, bounds.size.height - kJTBlurRadius * 2.0f);
	UIGraphicsBeginImageContextWithOptions(size, YES, 0.0f);
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIGraphicsBeginImageContextWithOptions(bounds.size, YES, 0.0f);
	CGContextRef finalImageContext = UIGraphicsGetCurrentContext();
	CGContextFillRect(finalImageContext, bounds);
	[image drawInRect:CGRectInset(bounds, kJTBlurRadius, kJTBlurRadius) blendMode:kCGBlendModeNormal alpha:0.7f];
	image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

- (UIImage*)blurrySnapshot
{
	CIImage *inputImage = [[CIImage alloc] initWithImage:[self snapshot]];
	
	CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
	[blurFilter setDefaults];
	[blurFilter setValue:inputImage forKey:kCIInputImageKey];
	[blurFilter setValue:@(kJTBlurRadius) forKey:kCIInputRadiusKey];
	
	CIImage *outputImage = [blurFilter valueForKey:kCIOutputImageKey];
	CIContext *context = [CIContext contextWithOptions:nil];
	
	return [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:[inputImage extent]]];
}

- (UIImageView*)blurryImageOverlayWithAlpha:(CGFloat)alpha
{
	UIImageView *overlay = [[UIImageView alloc] initWithFrame:[self bounds]];
	overlay.userInteractionEnabled = YES;
	overlay.image = [self blurrySnapshot];
	overlay.alpha = alpha;
	return overlay;
}

@end

@implementation JTModalManager

- (instancetype)init
{
	self = [super init];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarWillRotate:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
		
		_viewControllerStack = [[NSMutableArray alloc] init];
		_blurryOverlayStack = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)statusBarWillRotate:(NSNotification *)notification
{
	UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
	CGRect bounds = [keyWindow bounds];

	NSDictionary *userInfo = [notification userInfo];
	UIInterfaceOrientation orientation = [userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
	
	CGFloat rotation = 0;
	switch (orientation) {
		case UIInterfaceOrientationLandscapeLeft:
			rotation = -M_PI_2;
			break;
		case UIInterfaceOrientationLandscapeRight:
			rotation = M_PI_2;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			rotation = M_PI;
			break;
		case UIInterfaceOrientationPortrait:
		default:
			rotation = 0;
			break;
	}

	if ([_viewControllerStack count] > 0) {
		//TODO: Handle all modals in the stack
		UIViewController *controller = [_viewControllerStack lastObject];
		CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(rotation);
		CGFloat animationDuration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
		UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
		
		[controller willRotateToInterfaceOrientation:orientation duration:animationDuration];
		[UIView animateWithDuration:animationDuration animations:^{
			UIView *view = [_blurryOverlayStack lastObject];

			CGSize rotatedSize = CGRectApplyAffineTransform(view.bounds, rotationTransform).size;
			view.transform = rotationTransform;
			view.frame = CGRectMake(bounds.origin.x + roundf((bounds.size.width - rotatedSize.width) * 0.5f), bounds.origin.y + roundf((bounds.size.height - rotatedSize.height) * 0.5f), rotatedSize.width, rotatedSize.height);
		 } completion:^(BOOL finished) {
			 [controller didRotateFromInterfaceOrientation:currentOrientation];
		 }];
	}
}

@end
