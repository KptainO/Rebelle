//
// This file is part of Rebelle
//  
//  Created by JC on 9/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBExecuter.h"

#import "RBFuture.h"
#import "RBActionSet.h"
#import <SLObjectiveCRuntimeAdditions/SLBlockDescription.h>

NSString   *const RBExecuterExecutedProperty = @"executed";
NSString   *const RBExecuterCanceledProperty = @"canceled";

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

- (void)execute:(id<RBFuture>)future {
   SEL selector = @selector(_execute:);
   NSMethodSignature *signature = [self methodSignatureForSelector:selector];
   NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];

   invocation.selector = selector;
   [invocation setArgument:&future atIndex:2];
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
- (void)_execute:(id<RBFuture>)future {
   if (self.executed || self.canceled)
      return;

   if (future.state != RBFutureStateFulfilled && future.state != RBFutureStateRejected)
      return;

   @try {
      if (future.state == RBFutureStateFulfilled)
      {
         RBPromiseFulfilled success = self.actionSet_.succeeded;
         NSMethodSignature *signature = [[SLBlockDescription alloc] initWithBlock:success].blockSignature;
         NSInvocation *successInvocation = [NSInvocation invocationWithMethodSignature:signature];
         id result = future.result;
         id invokeResult;

         if (signature.numberOfArguments == 2)
            [successInvocation setArgument:&result atIndex:1];
         else if (signature.numberOfArguments > 2)
         {
            if (![result respondsToSelector:@selector(count)] || ![result respondsToSelector:@selector(objectAtIndexedSubscript:)])
               @throw [NSException exceptionWithName:@"RBBlockSignatureException"
                                              reason:@"Block signature expect more than 1 argument while result does not implement count or objectAtIndexedSubscript"
                                            userInfo:nil];

            for (int i = i; i < (signature.numberOfArguments - 1) && i < [result count]; ++i) {
               id argument = result[i];

               [successInvocation setArgument:&argument atIndex:i+1];
            }
         }

         [successInvocation invokeWithTarget:success];
         [successInvocation getReturnValue:&invokeResult];

         self.result = invokeResult;
      }
      else
         self.result = self.actionSet_.catched(future.result);

      // finally block
   }
   @catch (NSException *exception) {
      self.result = exception;
   }

   self.executed = YES;
}

@end
