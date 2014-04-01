//
// This file is part of Rebelle
//  
// Created by JC on 3/24/14.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBFutureArray.h"

// Private API
@interface RBFutureArray ()
@property(nonatomic, strong)NSMutableArray   *futures_;
@end

@implementation RBFutureArray

#pragma mark - Ctor/Dtor

+ (instancetype)arrayWithFuture:(id<RBFuture>)future {
   return [[self.class alloc] initWithFutures:future,nil];
}

+ (instancetype)arrayWithFutures:(id<RBFuture>)firstObj,... {
   va_list args;
   NSMutableArray *futures = [NSMutableArray array];

   va_start(args, firstObj);
   for (id<RBFuture> arg = firstObj; arg != nil; arg = va_arg(args, id<RBFuture>))
      [futures addObject:arg];
   va_end(args);

   return [[self.class alloc] initWithArray:futures];
}

- (instancetype)initWithFutures:(id<RBFuture>)firstObj,... {
   va_list args;
   NSMutableArray *futures = [NSMutableArray array];

   va_start(args, firstObj);
   for (id<RBFuture> arg = firstObj; arg != nil; arg = va_arg(args, id<RBFuture>))
      [futures addObject:arg];
   va_end(args);

   return [self initWithArray:futures];
}

- (id)init {
   return [self initWithArray:nil];
}

- (instancetype)initWithArray:(NSArray *)anArray {
   if (!(self = [super init]))
      return nil;

   self.futures_ = [NSMutableArray arrayWithArray:anArray];

   return self;
}


#pragma mark - Public methods

- (NSUInteger)count {
   return self.futures_.count;
}

- (id<RBFuture>)firstObject {
   return self.futures_.firstObject;
}

- (id<RBFuture>)lastObject {
   return self.futures_.lastObject;
}

- (NSUInteger)indexOfObject:(id<RBFuture>)future {
   return [self.futures_ indexOfObject:future];
}

- (id<RBFuture>)objectAtIndex:(NSUInteger)index {
   return [self.futures_ objectAtIndex:index];
}

- (id<RBFuture>)objectAtIndexedSubscript:(NSUInteger)idx {
   return [self.futures_ objectAtIndexedSubscript:idx];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
   return [self.futures_ countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - Protected methods

#pragma mark - Private methods

@end
