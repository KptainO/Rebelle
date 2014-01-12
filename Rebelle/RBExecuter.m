//
// This file is part of Rebelle
//  
//  Created by JC on 9/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBExecuter.h"

#import "RBResolver.h"
#import "RBActionSet.h"

NSString   *const RBExecuterExecutedProperty = @"executed";

/// Private API
@interface RBExecuter ()
@property(nonatomic, assign)BOOL    executed;
@property(nonatomic, assign)BOOL    canceled;
@property(nonatomic, strong)id      result;

/// original thread where object was created to ensure callbacks are executed on the same one
@property(nonatomic, weak)NSThread  *originalThread_;

@property(nonatomic, strong)RBActionSet   *actionSet_;

@end

@implementation RBExecuter

#pragma mark - Ctor/Dtor

+ (instancetype)executerWithActionSet:(RBActionSet *)actionSet {
   return [[self alloc] initWithActionSet:actionSet];
}

- (instancetype)initWithActionSet:(RBActionSet *)actionSet {
  if (!(self = [super init]))
    return nil;

   self.actionSet_ = actionSet;
   self.originalThread_ = [NSThread currentThread];

  return self;
}

#pragma mark - Public methods

- (void)execute:(RBResolver *)resolver {
   SEL selector = @selector(_execute:);
   NSMethodSignature *signature = [self methodSignatureForSelector:selector];
   NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];

   invocation.selector = selector;
   [invocation setArgument:&resolver atIndex:2];
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

   self.canceled = YES;
}

#pragma mark - Protected methods


#pragma mark - Private methods
- (void)_execute:(RBResolver *)resolver {
   if (self.executed || self.canceled)
      return;

   if (resolver.state != RBResolverStateFulfilled && resolver.state != RBResolverStateRejected)
      return;

   @try {
      if (resolver.state == RBResolverStateFulfilled)
         self.result = self.actionSet_.succeeded(resolver.result);
      else
         self.result = self.actionSet_.catched(resolver.result);

      // finally block
   }
   @catch (NSException *exception) {
      self.result = exception;
   }

   self.executed = YES;
}

@end
