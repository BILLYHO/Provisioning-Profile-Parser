//
//  ViewController.m
//  provisioning
//
//  Created by BILLY HO on 11/18/14.
//  Copyright (c) 2014 BILLY HO. All rights reserved.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import <Security/Security.h>

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	// Do any additional setup after loading the view.
	
	//Get the provisoning profile directory
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *docDir = [NSString stringWithFormat: @"/Users/%@/Library/MobileDevice/Provisioning\ Profiles/", NSUserName()];
	
	//Get a list of provisoning profile name
	NSArray *fileList = [[NSArray alloc] init];
	fileList = [fileManager contentsOfDirectoryAtPath:docDir error:nil];
	//NSLog(@"%@", fileList);
	
	//Parse every provisonng profile
	_dataArray = [[NSMutableArray alloc] init];
	for (NSString *fileName in fileList)
	{
		[self parseWithPath:[docDir stringByAppendingString:fileName]];
	}
	
	_listTableView.dataSource = self;
	_listTableView.delegate = self;
	[_listTableView reloadData];
}

- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];
	// Update the view, if already loaded.
}

#pragma NSTableView DataSourse
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [_dataArray count];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return 20.0f;
}

#pragma NSTableView Delegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSLog(@"%ld",(long)[[notification object] selectedRow]);
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
 
	// Get an existing cell with the MyView identifier if it exists
	NSTextField *result = [tableView makeViewWithIdentifier:@"MyView" owner:self];
 
	// There is no existing cell to reuse so create a new one
	if (result == nil) {
		
		// Create the new NSTextField with a frame of the {0,0} with the width of the table.
		// Note that the height of the frame is not really relevant, because the row height will modify the height.
		result = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
		
		// The identifier of the NSTextField instance is set to MyView.
		// This allows the cell to be reused.
		result.identifier = @"MyView";
	}
 
	// result is now guaranteed to be valid, either as a reused cell
	// or as a new cell, so set the stringValue of the cell to the
	// nameArray value at row
	
	if ([tableColumn.identifier isEqualToString: @"NumberColumn"])
	{
		result.stringValue = [NSString stringWithFormat:@"%ld", (long)row];
	}
	else if([tableColumn.identifier isEqualToString: @"AppIdColumn"])
	{
		result.stringValue = [_dataArray[row] objectForKey:@"AppIDName"];
	}
	else if([tableColumn.identifier isEqualToString: @"TypeColumn"] )
	{
		result.stringValue = [_dataArray[row] objectForKey:@"type"];
	}
	else if ([tableColumn.identifier isEqualToString: @"IdentifierColumn"])
	{
		result.stringValue = [_dataArray[row] objectForKey:@"identifier"];
	}
	else if ([tableColumn.identifier isEqualToString: @"TeamNameColumn"])
	{
		result.stringValue = [_dataArray[row] objectForKey:@"TeamName"];
	}
	
	result.backgroundColor = [NSColor clearColor];
	[result setBordered:NO];
	result.editable = NO;
	// Return the result
	return result;
 
}

#pragma Provisoning profile parser
- (int) parseWithPath:(NSString *)path
{
	CMSDecoderRef decoder = NULL;
	CFDataRef dataRef = NULL;
	NSString *plistString = nil;
	NSDictionary *plist = nil;
	
	NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
	
	@try
	{
		CMSDecoderCreate(&decoder);
		NSData *fileData = [NSData dataWithContentsOfFile:path];
		CMSDecoderUpdateMessage(decoder, fileData.bytes, fileData.length);
		CMSDecoderFinalizeMessage(decoder);
		CMSDecoderCopyContent(decoder, &dataRef);
		plistString = [[NSString alloc] initWithData:(__bridge NSData *)dataRef encoding:NSUTF8StringEncoding];
		plist = [plistString propertyList];
	}
	@catch (NSException *exception)
	{
		printf("Could not decode file.\n");
	}
	@finally
	{
		if (decoder) CFRelease(decoder);
		if (dataRef) CFRelease(dataRef);
	}
 

	if ([plist valueForKeyPath:@"ProvisionedDevices"])
	{
		if ([[plist valueForKeyPath:@"Entitlements.get-task-allow"] boolValue])
		{
			[dic setValue:@"debug" forKey:@"type"];
			printf("debug\n");
		}
		else
		{
			[dic setValue:@"ad-hoc" forKey:@"type"];
			printf("ad-hoc\n");
		}
	}
	else if ([[plist valueForKeyPath:@"ProvisionsAllDevices"] boolValue])
	{
		[dic setValue:@"enterprise" forKey:@"type"];
		printf("enterprise\n");
	}
	else
	{
		[dic setValue:@"appstore" forKey:@"type"];
		printf("appstore\n");
	}
	
	if ([plist valueForKey:@"AppIDName"])
	{
		[dic setValue:[plist valueForKey:@"AppIDName"] forKey:@"AppIDName"];
		printf("%s\n", [[plist valueForKey:@"AppIDName"] UTF8String]);
	}

	
	NSString *applicationIdentifier = [plist valueForKeyPath:@"Entitlements.application-identifier"];
	NSString *prefix = [[[plist valueForKeyPath:@"ApplicationIdentifierPrefix"] objectAtIndex:0] stringByAppendingString:@"."];
	[dic setValue:[applicationIdentifier stringByReplacingOccurrencesOfString:prefix withString:@""] forKey:@"identifier"];
	printf("%s\n", [[applicationIdentifier stringByReplacingOccurrencesOfString:prefix withString:@""] UTF8String]);
	
	

	if ([plist valueForKey:@"TeamName"])
	{
		[dic setValue:[plist valueForKey:@"TeamName"] forKey:@"TeamName"];
		printf("%s\n", [[plist valueForKey:@"TeamName"] UTF8String]);
	}

	
	[_dataArray addObject:dic];
	return 0;
}

@end
