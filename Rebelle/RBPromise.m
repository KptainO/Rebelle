//
// This file is part of Rebelle
//
//  Created by JC on 8/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBPromise.h"

#import "RBErrorException.h"

NSString *const RBPromisePropertyState = @"state";
NSString *const RBPromisePropertyResolved = @"resolved";

@interface RBPromise ()
@property(nonatomic, copy)RBThenableThen then;
@property(nonatomic, assign)RBPromiseState  state;

/// Resolve process has entirely been processed (state, callbacks, ...)
/// This promise has nothing to do anymore
@property(nonatomic, assign)BOOL completed_;

@property(nonatomic, strong)NSObject  *result_;

@property(nonatomic, strong)NSMutableArray  *promises_;
@property(nonatomic, copy)RBPromiseFulfilled onFulfilled_;
@property(nonatomic, copy)RBPromiseRejected onRejected_;

@end

@implementation RBPromise

@dynamic resolved;

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
      if ([this isResolved])
         [promise resolve:this.result_];

      return promise;
   };

   return self;
}

- (void)resolve:(id)value {
   id result = nil;

   if (value == self)
      @throw [NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"promise can't be resolved with self as resolving value"
                                   userInfo:nil];

   // Avoid a non pending promise to transition to another state
   // (https://github.com/promises-aplus/promises-spec#promise-states)
   //
   // Also avoid a pending promise waiting for its result to resolve (aka a promise) to run resolve
   // once again
   // https://github.com/promises-aplus/promises-spec#the-promise-resolution-procedure (2.1)
   if (![self isStatePending] || self.result_)
      return;

   self.result_ = value;

   if ([value isKindOfClass:[RBPromise class]])
      return [value addObserver:self
                     forKeyPath:RBPromisePropertyResolved
                        options:NSKeyValueObservingOptionInitial
                        context:(__bridge void *)(RBPromisePropertyState)];

   // @TODO: Refactor
   @try {
      if ([value isKindOfClass:[NSException class]])
         result = [self _reject:(NSException *)value];
      else if ([value isKindOfClass:[NSError class]])
         result = [self _reject:[RBErrorException exceptionWithError:value message:nil]];
      else
         result = [self _fulfill:value];
   }
   @catch (NSException *e) {
      result = e;
   }

   for (RBPromise *promise in self.promises_)
      [promise resolve:result];

   self.completed_ = YES;
}

+ (NSSet *)keyPathsForValuesAffectingResolved {
   return [NSSet setWithArray:@[@"state", @"completed_"]];
}

- (BOOL)isResolved {
   return ![self isStatePending] && self.completed_;
}

- (BOOL)isStatePending {
   return self.state == RBPromiseStatePending;
}

#pragma mark - Protected methods

- (id)_fulfill:(id)value {
   self.state = RBPromiseStateFulfilled;

   return self.onFulfilled_ ? self.onFulfilled_(self.result_) : value;
}

- (id)_reject:(NSException *)reason {
   self.state = RBPromiseStateRejected;

   return (self.onRejected_) ? self.onRejected_(reason) : reason;
}

#pragma mark - Private methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   RBPromise *promise = object;
   id result = nil;

   // Promise not yet resolved
   if (![promise isResolved])
      return;

   [self.result_ removeObserver:self forKeyPath:RBPromisePropertyResolved];

   // @TODO: Refactor
   @try {
      if (promise.state == RBPromiseStateRejected)
         result = [self _reject:(NSException *)promise.result_];
      else
         result = [self _fulfill:promise.result_];
   }
   @catch (NSException *e) {
      result = e;
   }

   for (RBPromise *promise in self.promises_)
      [promise resolve:result];

   self.completed_ = YES;
}

@end
