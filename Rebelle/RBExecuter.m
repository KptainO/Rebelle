//
// This file is part of Rebelle
//  
//  Created by JC on 9/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBExecuter.h"

#import "RBPromise.h"

NSString   *const RBExecuterExecutedProperty = @"executed";

/// Private API
@interface RBExecuter ()
@property(nonatomic, assign)BOOL    executed;
@property(nonatomic, strong)id      result;

/// original thread where object was created to ensure callbacks are executed on the same one
@property(nonatomic, weak)NSThread  *originalThread_;
@property(nonatomic, assign)BOOL    canceled_;

@end

@implementation RBExecuter

#pragma mark - Ctor/Dtor

- (id)init {
  if (!(self = [super init]))
    return nil;

   self.originalThread_ = [NSThread currentThread];

  return self;
}

#pragma mark - Public methods

- (void)execute:(ExecuteCallback)callback withValue:(id)value {
   SEL selector = @selector(_execute:withValue:);
   NSMethodSignature *signature = [self methodSignatureForSelector:selector];
   NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];

   callback = [callback copy];

   invocation.selector = selector;
   [invocation setArgument:&callback atIndex:2];
   [invocation setArgument:&value atIndex:3];
   [invocation retainArguments];

   // Execute method on originalThread no matter if it is current thread or not
   // Plus queue it at the end of the thread run loop
   [invocation performSelector:@selector(invokeWithTarget:)
                onThread:self.originalThread_
              withObject:self
           waitUntilDone:NO];
}

- (void)cancel {
   // Too late => nothing to do
   if (self.executed)
      return;

   self.canceled_ = YES;
}

#pragma mark - Protected methods


#pragma mark - Private methods
- (void)_execute:(ExecuteCallback)callback withValue:(id)value {
   if (self.executed || self.canceled_)
      return;

   @try {
      self.result = !callback ? value : callback(value);
   }
   @catch (NSException *exception) {
      self.result = exception;
   }

   self.executed = YES;
}

@end
