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
   NSInvocation *invocation = nil;

   if ([NSThread currentThread] != self.originalThread_)
   {
      invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:_cmd]];

      invocation.target = self;

      [invocation setArgument:&callback atIndex:2];
      [invocation setArgument:&value atIndex:3];

      [invocation retainArguments];

      return [self performSelector:@selector(invoke) onThread:self.originalThread_ withObject:nil waitUntilDone:NO];
   }

   [self _execute:^{
      @try {
         self.result = !callback ? value : callback(value);
      }
      @catch (NSException *exception) {
         self.result = exception;
      }
   }];
}

#pragma mark - Protected methods


#pragma mark - Private methods
- (void)_execute:(dispatch_block_t)block {
   if (self.executed)
      return;
   
   block();
   self.executed = YES;
}

@end
