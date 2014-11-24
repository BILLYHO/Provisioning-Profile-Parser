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

- (void)viewDidLoad
{
	[super viewDidLoad];

	// Do any additional setup after loading the view.
	
	//Get the provisoning profile directory
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *docDir = [NSString stringWithFormat: @"/Users/%@/Library/MobileDevice/Provisioning Profiles/", NSUserName()];
	
	//Get a list of provisoning profile name
	NSArray *fileList = [[NSArray alloc] init];
	fileList = [fileManager contentsOfDirectoryAtPath:docDir error:nil];
	//NSLog(@"%@", fileList);
	
	//Parse every provisonng profile
	_dataArray = [[NSMutableArray alloc] init];
	for (int i=0; i<fileList.count; i++)
	{
		NSMutableDictionary *dic = [self parseWithPath:[docDir stringByAppendingString:fileList[i]] atIndex:@(i+1)];
		[_dataArray addObject:dic];
	}
	
	//Initialize TableView
	[self initTableView];
	
}

- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];
	// Update the view, if already loaded.
}


- (void)initTableView
{
	_listTableView.dataSource = self;
	_listTableView.delegate = self;
	[_listTableView reloadData];
	
	NSTableColumn *tableColumn = [_listTableView tableColumnWithIdentifier:@"IndexColumn"];
	NSSortDescriptor *indexColumnSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"Index"
																				ascending:YES
																				 selector:@selector(compare:)];
	[tableColumn setSortDescriptorPrototype:indexColumnSortDescriptor];

	
	tableColumn = [_listTableView tableColumnWithIdentifier:@"AppIdColumn"];
	NSSortDescriptor *appIdColumnSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"AppIDName"
																				ascending:YES
																				 selector:@selector(localizedCompare:)];
	[tableColumn setSortDescriptorPrototype:appIdColumnSortDescriptor];
	
	tableColumn = [_listTableView tableColumnWithIdentifier:@"TypeColumn"];
	NSSortDescriptor *typeColumnSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"Type"
																			   ascending:NO
																				selector:@selector(localizedCompare:)];
	[tableColumn setSortDescriptorPrototype:typeColumnSortDescriptor];
	
	tableColumn = [_listTableView tableColumnWithIdentifier:@"IdentifierColumn"];
	NSSortDescriptor *identifierColumnSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"Identifier"
																			   ascending:YES
																					  selector:@selector(localizedCompare:)];
	[tableColumn setSortDescriptorPrototype:identifierColumnSortDescriptor];
	
	tableColumn = [_listTableView tableColumnWithIdentifier:@"TeamNameColumn"];
	NSSortDescriptor *teamNameColumnSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"TeamName"
																				   ascending:YES
																					selector:@selector(localizedCompare:)];
	[tableColumn setSortDescriptorPrototype:teamNameColumnSortDescriptor];

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

-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
	
	NSArray *newDescriptors = [tableView sortDescriptors];//@[typeColumnSortDescriptor];
	[_dataArray sortUsingDescriptors:newDescriptors];
	[tableView reloadData];
}

#pragma NSTableView Delegate
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
 
	// Get an existing cell with the MyView identifier if it exists
	NSTextField *result = [tableView makeViewWithIdentifier:@"MyView" owner:self];
 
	// There is no existing cell to reuse so create a new one
	if (result == nil) {
		result = [[NSTextField alloc] init];
		
		// The identifier of the NSTextField instance is set to MyView.
		// This allows the cell to be reused.
		result.identifier = @"MyView";
	}
 
	
	if ([tableColumn.identifier isEqualToString: @"IndexColumn"])
	{
		result.stringValue = [_dataArray[row] objectForKey:@"Index"];
	}
	else if([tableColumn.identifier isEqualToString: @"AppIdColumn"])
	{
		result.stringValue = [_dataArray[row] objectForKey:@"AppIDName"];
	}
	else if([tableColumn.identifier isEqualToString: @"TypeColumn"] )
	{
		result.stringValue = [_dataArray[row] objectForKey:@"Type"];
	}
	else if ([tableColumn.identifier isEqualToString: @"IdentifierColumn"])
	{
		result.stringValue = [_dataArray[row] objectForKey:@"Identifier"];
	}
	else if ([tableColumn.identifier isEqualToString: @"TeamNameColumn"])
	{
		result.stringValue = [_dataArray[row] objectForKey:@"TeamName"];
	}
	
	result.backgroundColor = [NSColor clearColor];
	[result setBordered:NO];
	result.editable = NO;
	
	return result;
 
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSLog(@"%ld",(long)[[notification object] selectedRow]);
}

- (IBAction)didExportButtonClicked:(id)sender
{
	//NSLog(@"%ld", (long)[_listTableView selectedRow]);
	//NSLog(@"%@", [_dataArray[[_listTableView selectedRow]] objectForKey:@"Entitlements"]);
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	[savePanel setAllowedFileTypes:@[@"plist"]];
	[savePanel setNameFieldStringValue:@"Entitlements"];
	[savePanel setTitle:@"Export Entitlements Plist"];
	
	
	NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:[_dataArray[[_listTableView selectedRow]] objectForKey:@"Entitlements"] format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListImmutable error:nil];
	
	if ([savePanel runModal] == NSModalResponseOK)
	{
		[plistData writeToURL:[savePanel URL] atomically:YES];
	}
	
}

#pragma Provisoning profile parser
- (NSMutableDictionary *) parseWithPath:(NSString *)path atIndex:(NSNumber*)index
{
	CMSDecoderRef decoder = NULL;
	CFDataRef dataRef = NULL;
	NSString *plistString = nil;
	NSDictionary *plist = nil;
	
	NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
	[dic setObject:index forKey:@"Index"];
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
 
	
	NSLog(@"%@", [plist valueForKey:@"DeveloperCertificates"]);
	
	if([plist valueForKeyPath:@"Entitlements"])
	{
		[dic setObject:[plist valueForKeyPath:@"Entitlements"] forKey:@"Entitlements"];
	}
	
	
	if ([plist valueForKeyPath:@"ProvisionedDevices"])
	{
		if ([[plist valueForKeyPath:@"Entitlements.get-task-allow"] boolValue])
		{
			[dic setObject:@"Debug" forKey:@"Type"];
			printf("Debug\n");
		}
		else
		{
			[dic setObject:@"Ad-Hoc" forKey:@"Type"];
			printf("Ad-Hoc\n");
		}
	}
	else if ([[plist valueForKeyPath:@"ProvisionsAllDevices"] boolValue])
	{
		[dic setObject:@"Enterprise" forKey:@"Type"];
		printf("Enterprise\n");
	}
	else
	{
		[dic setObject:@"Appstore" forKey:@"Type"];
		printf("Appstore\n");
	}
	
	if ([plist valueForKey:@"AppIDName"])
	{
		[dic setObject:[plist valueForKey:@"AppIDName"] forKey:@"AppIDName"];
		printf("%s\n", [[plist valueForKey:@"AppIDName"] UTF8String]);
	}

	
	NSString *applicationIdentifier = [plist valueForKeyPath:@"Entitlements.application-identifier"];
	NSString *prefix = [[[plist valueForKeyPath:@"ApplicationIdentifierPrefix"] objectAtIndex:0] stringByAppendingString:@"."];
	NSString *indentifier = [applicationIdentifier stringByReplacingOccurrencesOfString:prefix withString:@""];
	[dic setObject:indentifier forKey:@"Identifier"];
	printf("%s\n", [indentifier UTF8String]);
	
	

	if ([plist valueForKey:@"TeamName"])
	{
		[dic setObject:[plist valueForKey:@"TeamName"] forKey:@"TeamName"];
		printf("%s\n", [[plist valueForKey:@"TeamName"] UTF8String]);
	}

	
	
	return dic;
}

@end
