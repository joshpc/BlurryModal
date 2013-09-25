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

@implementation JTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	UIViewController *controller = [[UIViewController alloc] init];
	controller.title = @"basdf";
	controller.navigationItem.title = @"sdfaasdf";
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"warning"]];
	imageView.frame = CGRectMake(100, 100, imageView.frame.size.width, imageView.frame.size.height);
	[[controller view] setBackgroundColor:[UIColor greenColor]];
	[[controller view] addSubview:imageView];
	
	[self.window setRootViewController:controller];
	[self.window makeKeyAndVisible];
	
	double delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		UIViewController *newController = [[JTSampleController alloc] init];
		newController.view.backgroundColor = [UIColor orangeColor];
		[controller pushModalViewController:newController animated:YES completion:^{

			double delayInSeconds = 2.0;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//				[controller popModalViewController:YES completion:^{
//					NSLog(@"Done");
//				}];
			});
			
		}];
	});
	
	return YES;
}

@end
