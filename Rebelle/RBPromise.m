//
// This file is part of Rebelle
//
//  Created by JC on 8/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBPromise.h"

@interface RBPromise ()
@property(nonatomic, assign)RBPromiseState  state_;
@property(nonatomic, strong)id  result_;
@property(nonatomic, copy)RBThenableThen then;

@property(nonatomic, strong)NSMutableArray  *promises_;
@property(nonatomic, copy)RBPromiseFulfilled onFulfilled_;
@property(nonatomic, copy)RBPromiseRejected onRejected_;

@end

@implementation RBPromise

- (id)init {
   if (!(self = [super init]))
      return nil;

   __block typeof(self) this = self;

   self.promises_ = [NSMutableArray new];

   // Define "then" block which will be called each time user do promise.then()
   // It save defined blocks + associated generated promise
   self.then = ^id<RBThenable>(RBPromiseFulfilled onFulfilled, RBPromiseRejected onRejected) {
      RBPromise *promise = [RBPromise new];

      promise.onFulfilled_ = onFulfilled;
      promise.onRejected_ = onRejected;

      [this.promises_ addObject:promise];

      // If our current promise is already resolved, then launch our new promise resolution
      // procedure (otherwise it won't never be called automatically)
      if ([this _isResolved])
         [promise resolve:this.result_];

      return promise;
   };

   return self;
}

- (void)resolve:(id)value {
   id result = nil;

   // Avoid a fulfilled/rejected promise to transition to another state
   // (https://github.com/promises-aplus/promises-spec#promise-states)
   if ([self _isResolved])
      return;

   @try {
      if ([value isKindOfClass:[NSException class]])
         result = [self _reject:(NSException *)value];
      else if ([value isKindOfClass:[NSError class]])
         ;
      else
         result = [self _fulfill:value];

      self.result_ = result ?: value;
   }
   @catch (NSException *e) {
      self.result_ = e;
   }
   // else if [value isKindOfClass:[RBPromise class]]

   for (RBPromise *promise in self.promises_)
      [promise resolve:self.result_];
}

#pragma mark - Protected methods

- (id)_fulfill:(id)value {
   self.state_ = RBPromiseStateFulfilled;

   return self.onFulfilled_ ? (__bridge id)self.onFulfilled_(self.result_) : nil;
}

- (id)_reject:(NSException *)reason {
   self.state_ = RBPromiseStateRejected;

   return (self.onRejected_) ? (__bridge id)self.onRejected_(reason) : nil;
}

- (BOOL)_isResolved {
   return (self.state_ != RBPromiseStatePending);
}

@end
