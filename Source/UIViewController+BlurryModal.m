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
static NSMutableArray *_blurryOverlayStack;

static void callCompletionBlock(JTCompletionBlock completion) {
	if (completion) {
		completion();
	}
}

@interface UIWindow (Snapshot)
- (UIImageView*)blurryImageOverlayWithAlpha:(CGFloat)alpha;
@end

@implementation UIViewController (JTModal)

+ (void)initialize
{
	if ([self class] == [UIViewController class]) {
		_viewControllerStack = [[NSMutableArray alloc] init];
		_blurryOverlayStack = [[NSMutableArray alloc] init];
	}
}

#pragma mark - Push Modal View Controller

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
	CGSize viewSize = bounds.size;
	
	if ([controller conformsToProtocol:@protocol(JTBlurryModal)]) {
		viewSize = [(id<JTBlurryModal>)controller sizeWhenPresentedModally];
	}
	
	CGFloat alpha = animated ? 0.0f : 1.0f;
	UIImageView *overlay = [keyWindow blurryImageOverlayWithAlpha:alpha];
	[keyWindow addSubview:overlay];
	[_blurryOverlayStack addObject:overlay];
	
	UIView *view = controller.view;
	view.alpha = alpha;
	view.frame = CGRectMake(bounds.origin.x + roundf((bounds.size.width - viewSize.width) * 0.5f), bounds.origin.y + roundf((bounds.size.height - viewSize.height) * 0.5f), viewSize.width, viewSize.height);
	[keyWindow addSubview:view];
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
		
		[_viewControllerStack removeObject:controller];
		[_blurryOverlayStack removeObject:overlay];
		
		[self completeControllerDismissal:animated controller:controller completion:completion overlay:overlay];
	}
}

#pragma mark - Appearing and Disappearing

- (void)completeControllerTransition:(UIViewController*)controller overlay:(UIImageView *)overlay animated:(BOOL)animated completion:(void (^)())completion
{
	[controller viewWillAppear:animated];
	if (animated) {
		[UIView animateWithDuration:kJTBlurAnimationDuration animations:^{
			overlay.alpha = 1.0f;
			controller.view.alpha = 1.0f;
		} completion:^(BOOL finished) {
			[controller viewDidAppear:animated];
			callCompletionBlock(completion);
		}];
	}
	else {
		[controller viewDidAppear:animated];
		callCompletionBlock(completion);
	}
}

- (void)completeControllerDismissal:(BOOL)animated controller:(UIViewController *)controller completion:(void (^)())completion overlay:(UIImageView *)overlay
{
	[controller viewWillDisappear:animated];
	if (animated) {
		[UIView animateWithDuration:kJTBlurAnimationDuration animations:^{
			overlay.alpha = 0.0f;
			controller.view.alpha = 0.0f;
		} completion:^(BOOL finished) {
			[controller viewDidDisappear:animated];
			[overlay removeFromSuperview];
			[controller.view removeFromSuperview];
			callCompletionBlock(completion);
		}];
	}
	else {
		[controller viewDidDisappear:animated];
		callCompletionBlock(completion);
	}
}

@end

@implementation UIWindow (Snapshot)

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
