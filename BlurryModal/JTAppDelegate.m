//
//  JTAppDelegate.m
//  BlurryModal
//
//  Created by Joshua Tessier on 2013-09-24.
//  Copyright (c) 2013 Joshua Tessier. All rights reserved.
//

#import "JTAppDelegate.h"
#import "UIViewController+BlurryModal.h"
#import "JTSampleController.h"

@implementation JTAppDelegate {
	UIViewController *_rootViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	_rootViewController = [[UIViewController alloc] init];
	_rootViewController.view.backgroundColor = [UIColor whiteColor];
	_rootViewController.title = @"Sample";
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"warning"]];
	imageView.frame = CGRectMake(100, 100, imageView.frame.size.width, imageView.frame.size.height);
	[[_rootViewController view] addSubview:imageView];
	
	[self.window setRootViewController:_rootViewController];
	[self.window makeKeyAndVisible];
	
	[self samplePush];
	
	return YES;
}

- (void)samplePush
{
	double delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[_rootViewController pushModalViewController:[[JTSampleController alloc] init] animated:YES completion:^{
			[self samplePop];
		}];
	});
}

- (void)samplePop
{
	double delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[_rootViewController popModalViewController:YES completion:^{
			[self samplePush];
		}];
	});
}

@end
