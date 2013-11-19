//
//  JTSampleController.m
//  BlurryModal
//
//  Created by Joshua Tessier on 2013-09-24.
//  Copyright (c) 2013 Joshua Tessier. All rights reserved.
//

#import "JTSampleController.h"
#import "JTSampleView.h"

@implementation JTSampleController {
	JTSampleView *_view;
}

- (void)loadView
{
	_view = [[JTSampleView alloc] init];
	self.view = _view;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[_view animateIn];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[_view animateOut];
}

@end
