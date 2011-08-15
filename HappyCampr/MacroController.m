//
//  RoboRulesController.m
//  HappyCampr
//
//  Created by Randall Brown on 8/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MacroController.h"
#import "NSFileManager+DirectoryLocations.h"

@implementation MacroController
@synthesize macros;

+(NSString*)macroFilePath
{
   return [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:@"macros.plist"];
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
   macros = [[NSKeyedUnarchiver unarchiveObjectWithFile:[[self class] macroFilePath]] retain];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
   return [macros count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
   if( rowIndex >= [macros count] )
      return nil;
   
   if( [[aTableColumn identifier] isEqualToString:@"shortValue"] )
   {
      return [[macros objectAtIndex:rowIndex] shortenedValue];
   }
   else if( [[aTableColumn identifier] isEqualToString:@"expandedValue"] )
   {
      return [[macros objectAtIndex:rowIndex] expandedValue];
   }
   return @"";
}

-(void)addRule:(Macro*)macro
{
   if( !macros )
   {
      macros = [[NSMutableArray alloc] init];
   }
   
   [macros addObject:macro];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
   return YES;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
   if( [[aTableColumn identifier] isEqualToString:@"shortValue"] )
   {
      [[macros objectAtIndex:rowIndex] setShortenedValue:anObject];
   }
   else if( [[aTableColumn identifier] isEqualToString:@"expandedValue"] )
   {
      [[macros objectAtIndex:rowIndex] setExpandedValue:anObject];
   }   
   
   [NSKeyedArchiver archiveRootObject:macros toFile:[[self class] macroFilePath]];
}

-(void)addMacro:(Macro *)macro
{
   if( !macros )
   {
      macros = [[NSMutableArray alloc] init];
   }
   [macros addObject:macro];
}

- (IBAction)addRemoveMacro:(id)sender 
{
   
   NSInteger selectedSegment = [sender selectedSegment];
   
   if( selectedSegment == 0 )
   {
      Macro *macro = [[[Macro alloc] init] autorelease];
      [self addMacro:macro];
      [macroTable reloadData];
      [macroTable editColumn:0 row:[macros count]-1 withEvent:nil select:YES];
   }
   else if( selectedSegment == 1 )
   {      
      if( [macroTable selectedRow] != -1 )
      {
         [macros removeObjectAtIndex:[macroTable selectedRow]]; 
         [macroTable reloadData];
      }
      [NSKeyedArchiver archiveRootObject:macros
                                  toFile:[[self class] macroFilePath]];
   }
}

-(NSString *)processMacrosWithMessage:(NSString*)message
{
   for( Macro* macro in macros )
   {
      if( [message isEqualToString:macro.shortenedValue] )
      {
         return macro.expandedValue;
      }
   }
   
   return nil;
}
@end
