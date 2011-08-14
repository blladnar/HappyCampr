//
//  RoboRulesController.m
//  HappyCampr
//
//  Created by Randall Brown on 8/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RoboRulesController.h"
#import "NSFileManager+DirectoryLocations.h"

@implementation RoboRulesController
@synthesize rules;

+(NSString*)roboRuleFilePath
{
   return [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:@"roboRules.plist"];
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)awakeFromNib
{
  // [self addRule:[[RoboRule alloc] initWithTrigger:@"hello" andResponse:@"world"]];
   rules = [[NSKeyedUnarchiver unarchiveObjectWithFile:[[self class] roboRuleFilePath]] retain];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
   return [rules count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
   if( rowIndex >= [rules count] )
      return nil;
   
   if( [[aTableColumn identifier] isEqualToString:@"trigger"] )
   {
      return [[rules objectAtIndex:rowIndex] trigger];
   }
   else if( [[aTableColumn identifier] isEqualToString:@"response"] )
   {
      return [[rules objectAtIndex:rowIndex] response];
   }
   return @"";
}

-(void)addRule:(RoboRule*)rule
{
   if( !rules )
   {
      rules = [[NSMutableArray alloc] init];
   }
   
   [rules addObject:rule];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
   return YES;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
   if( [[aTableColumn identifier] isEqualToString:@"trigger"] )
   {
      [[rules objectAtIndex:rowIndex] setTrigger:anObject];
   }
   else if( [[aTableColumn identifier] isEqualToString:@"response"] )
   {
      [[rules objectAtIndex:rowIndex] setResponse:anObject];
   }   
   
   [NSKeyedArchiver archiveRootObject:rules toFile:[[self class] roboRuleFilePath]];
}


- (IBAction)removeRulePressed:(id)sender 
{
   
   NSInteger selectedSegment = [sender selectedSegment];
   
   if( selectedSegment == 0 )
   {
      RoboRule *rule = [[[RoboRule alloc] initWithTrigger:@"" andResponse:@""] autorelease];
      [self addRule:rule];
      [ruleTable reloadData];
      [ruleTable editColumn:0 row:[rules count]-1 withEvent:nil select:YES];
   }
   else if( selectedSegment == 1 )
   {      
      if( [ruleTable selectedRow] != -1 )
      {
         [rules removeObjectAtIndex:[ruleTable selectedRow]]; 
         [ruleTable reloadData];
      }
      [NSKeyedArchiver archiveRootObject:rules toFile:[[self class] roboRuleFilePath]];
   }
}
@end
