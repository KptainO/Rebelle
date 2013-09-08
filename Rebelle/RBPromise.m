//
// This file is part of Rebelle
//
//  Created by JC on 8/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBPromise.h"

NSString *const RBPromisePropertyState = @"state";

@interface RBPromise ()
@property(nonatomic, copy)RBThenableThen then;
@property(nonatomic, assign)RBPromiseState  state;


@property(nonatomic, strong)NSObject  *result_;

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
   //
   // Also avoid a pending promise waiting for its result to resolve (aka a promise) to run resolve
   // one again
   // https://github.com/promises-aplus/promises-spec#the-promise-resolution-procedure (2.1)
   if ([self _isResolved] || self.result_)
      return;

   self.result_ = value;

   if ([value isKindOfClass:[RBPromise class]])
      return [value addObserver:self
                     forKeyPath:RBPromisePropertyState
                        options:NSKeyValueObservingOptionInitial
                        context:(__bridge void *)(RBPromisePropertyState)];

   // @TODO: Refactor
   @try {
      if ([value isKindOfClass:[NSException class]])
         result = [self _reject:(NSException *)value];
      else if ([value isKindOfClass:[NSError class]])
         ;
      else
         result = [self _fulfill:value];
   }
   @catch (NSException *e) {
      result = e;
   }

   result = result ?: value;
   for (RBPromise *promise in self.promises_)
      [promise resolve:result];
}

#pragma mark - Protected methods

- (id)_fulfill:(id)value {
   self.state = RBPromiseStateFulfilled;

   return self.onFulfilled_ ? self.onFulfilled_(self.result_) : nil;
}

- (id)_reject:(NSException *)reason {
   self.state = RBPromiseStateRejected;

   return (self.onRejected_) ? self.onRejected_(reason) : nil;
}

- (BOOL)_isResolved {
   return (self.state != RBPromiseStatePending);
}

#pragma mark - Private methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   RBPromise *promise = object;
   id result = nil;

   // Promise not yet resolved
   if (![promise _isResolved])
      return;

   [self.result_ removeObserver:self forKeyPath:RBPromisePropertyState];

   // @TODO: Refactor
   @try {
      if (promise.state == RBPromiseStateFulfilled)
         result = [self _reject:(NSException *)promise.result_];
      else
         result = [self _fulfill:promise.result_];
   }
   @catch (NSException *e) {
      result = e;
   }

   result = result ?: promise.result_;
   for (RBPromise *promise in self.promises_)
      [promise resolve:result];
}

@end
