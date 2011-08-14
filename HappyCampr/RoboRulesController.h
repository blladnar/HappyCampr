//
//  RoboRulesController.h
//  HappyCampr
//
//  Created by Randall Brown on 8/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RoboRule.h"

@interface RoboRulesController : NSObject<NSTableViewDelegate, NSTableViewDataSource>
{
   NSMutableArray *rules;
   IBOutlet NSTableView *ruleTable;
}

-(void)addRule:(RoboRule*)rule;

@property (readonly) NSArray *rules;
- (IBAction)addRulePressed:(id)sender;
- (IBAction)removeRulePressed:(id)sender;

@end
