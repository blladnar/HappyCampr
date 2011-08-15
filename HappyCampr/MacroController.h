//
//  RoboRulesController.h
//  HappyCampr
//
//  Created by Randall Brown on 8/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Macro.h"

@interface MacroController : NSObject<NSTableViewDelegate, NSTableViewDataSource>
{
   NSMutableArray *macros;
   IBOutlet NSTableView *macroTable;
}

-(void)addMacro:(Macro*)macro;

-(NSString *)processMacrosWithMessage:(NSString*)message;
- (IBAction)addRemoveMacro:(id)sender;

@property (readonly) NSArray *macros;

@end
