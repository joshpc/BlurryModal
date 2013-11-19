//
//  JTSampleView.m
//  BlurryModal
//
//  Created by Joshua Tessier on 11/19/2013.
//  Copyright (c) 2013 Joshua Tessier. All rights reserved.
//

#import "JTSampleView.h"

@implementation JTSampleView {
	UILabel *_label;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		_label = [[UILabel alloc] init];
		_label.text = @"Bananaphone!";
		_label.textAlignment = NSTextAlignmentCenter;
		_label.font = [UIFont systemFontOfSize:18.0f];
		_label.backgroundColor = [UIColor clearColor];
		[self addSubview:_label];
	}
	return self;
}

- (void)animateIn
{
	CGRect bounds = [self bounds];
	_label.frame = CGRectMake(bounds.origin.x + bounds.size.width, bounds.origin.y + 100.0f, bounds.size.width, [[_label text] sizeWithAttributes:@{NSFontAttributeName : _label.font}].height);
	[UIView animateWithDuration:0.7f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		_label.frame = CGRectOffset(_label.frame, -bounds.size.width, 0.0f);
	} completion:nil];
}

- (void)animateOut
{
	CGRect bounds = [self bounds];
	_label.frame = CGRectMake(bounds.origin.x, bounds.origin.y + 100.0f, bounds.size.width, [[_label text] sizeWithAttributes:@{NSFontAttributeName : _label.font}].height);
	[UIView animateWithDuration:0.7f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		_label.frame = CGRectOffset(_label.frame, -bounds.size.width, 0.0f);
	} completion:nil];
}

@end
