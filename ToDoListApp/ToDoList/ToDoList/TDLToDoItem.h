//
//  TDLToDoItem.h
//  ToDoList
//
//  Created by Andrés Ruiz on 9/18/14.
//  Copyright (c) 2014 Andrés Ruiz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDLToDoItem : NSObject

@property NSString *itemName;
@property BOOL completed;
@property (readonly) NSDate *creationDate;

@end
