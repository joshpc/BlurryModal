//
//  JTSampleController.m
//  BlurryModal
//
//  Created by Joshua Tessier on 2013-09-24.
//  Copyright (c) 2013 Joshua Tessier. All rights reserved.
//

#import "JTSampleController.h"

@implementation JTSampleController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 5;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"demo"];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"demo"];
	}
	cell.textLabel.text = @"Banana";
	return cell;
}

@end
