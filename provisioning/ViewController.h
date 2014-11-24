//
//  ViewController.h
//  provisioning
//
//  Created by BILLY HO on 11/18/14.
//  Copyright (c) 2014 BILLY HO. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (strong) IBOutlet NSTableView *listTableView;

@property (strong) IBOutlet NSButton *exportButton;

@property (strong, nonatomic) NSMutableArray *dataArray;

@end

