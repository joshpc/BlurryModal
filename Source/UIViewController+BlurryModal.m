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

static NSMutableArray *_viewControllerStack;
static NSMutableArray *_containerViewStack;
static NSMutableArray *_blurryOverlayStack;

static void callCompletionBlock(JTCompletionBlock completion) {
	if (completion) {
		completion();
	}
}

@interface UIView (Snapshot)
- (UIImageView*)blurryImageOverlayWithAlpha:(CGFloat)alpha;
@end

@implementation UIViewController (JTModal)

+ (void)initialize
{
	if ([self class] == [UIViewController class]) {
		_viewControllerStack = [[NSMutableArray alloc] init];
		_blurryOverlayStack = [[NSMutableArray alloc] init];
		_containerViewStack = [[NSMutableArray alloc] init];
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
	
	if ([rootController conformsToProtocol:@protocol(JTBlurryModal)]) {
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
	CGRect bounds = [self.view bounds];
	CGSize viewSize = [UIViewController preferredModalSizeForController:controller constrainedTo:bounds];
	
	[controller willMoveToParentViewController:self];
	
	CGFloat alpha = animated ? 0.0f : 1.0f;
	UIImageView *overlay = [self.view blurryImageOverlayWithAlpha:alpha];
	[self.view addSubview:overlay];
	[_blurryOverlayStack addObject:overlay];
	
	UIView *view = controller.view;
	view.alpha = alpha;
	view.frame = CGRectMake(0.0f, 0.0f, viewSize.width, viewSize.height);
	
	UIView *containerView = [[UIView alloc] init];
	containerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
	containerView.backgroundColor = [UIColor clearColor];
	containerView.frame = CGRectMake(bounds.origin.x + roundf((bounds.size.width - viewSize.width) * 0.5f), bounds.origin.y + roundf((bounds.size.height - viewSize.height) * 0.5f), viewSize.width, viewSize.height);
	[containerView addSubview:view];
	
	[self.view addSubview:containerView];
	[self addChildViewController:controller];
	[_containerViewStack addObject:containerView];
	[_viewControllerStack addObject:controller];

	[self completeControllerTransition:controller overlay:overlay animated:animated completion:completion];
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
	if ([_viewControllerStack count] > 0) {
		UIViewController *controller = [_viewControllerStack lastObject];
		UIImageView *overlay = [_blurryOverlayStack lastObject];
		UIView *containerView = [_containerViewStack lastObject];
		[containerView removeFromSuperview];
		
		[controller willMoveToParentViewController:nil];
		[controller.view removeFromSuperview];
		[controller removeFromParentViewController];
		[controller didMoveToParentViewController:nil];
		
		[_viewControllerStack removeObject:controller];
		[_blurryOverlayStack removeObject:overlay];
		[_containerViewStack removeObject:containerView];
		
		[self completeControllerDismissal:animated controller:controller completion:completion overlay:overlay];
	}
}

#pragma mark - Appearing and Disappearing

- (void)completeControllerTransition:(UIViewController*)controller overlay:(UIImageView *)overlay animated:(BOOL)animated completion:(void (^)())completion
{
	if (animated) {
		[UIView animateWithDuration:kJTBlurAnimationDuration animations:^{
			overlay.alpha = 1.0f;
			controller.view.alpha = 1.0f;
		} completion:^(BOOL finished) {
			[controller didMoveToParentViewController:self];
			callCompletionBlock(completion);
		}];
	}
	else {
		callCompletionBlock(completion);
	}
}

- (void)completeControllerDismissal:(BOOL)animated controller:(UIViewController *)controller completion:(void (^)())completion overlay:(UIImageView *)overlay
{
	if (animated) {
		[UIView animateWithDuration:kJTBlurAnimationDuration animations:^{
			overlay.alpha = 0.0f;
			controller.view.alpha = 0.0f;
		} completion:^(BOOL finished) {
			[controller didMoveToParentViewController:nil];
			callCompletionBlock(completion);
		}];
	}
	else {
		callCompletionBlock(completion);
	}
}

@end

@implementation UIView (Snapshot)

- (UIImage*)snapshot
{
	UIGraphicsBeginImageContextWithOptions([self bounds].size, YES, 0.0f);
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
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
	CGFloat overExtend = kJTBlurRadius * 2.0f;
	CGRect bounds = [self bounds];
	UIImageView *overlay = [[UIImageView alloc] initWithFrame:CGRectMake(bounds.origin.x - overExtend, bounds.origin.y - overExtend, bounds.size.width + 2.0f * overExtend, bounds.size.height + 2.0f * overExtend)];
	overlay.image = [self blurrySnapshot];
	overlay.alpha = alpha;
	return overlay;
}

@end
