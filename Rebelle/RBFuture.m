//
// This file is part of Rebelle
//  
// Created by JC on 12/6/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBFuture.h"

#import "RBErrorException.h"

NSString *const RBFuturePropertyState = @"state";

// Private API
@interface RBFuture ()
@property(nonatomic, assign)RBFutureState       state;
@property(nonatomic, strong)id                  result;
@end

@implementation RBFuture

@synthesize result = _result;

#pragma mark - Ctor/Dtor

- (void)dealloc {
   self.result = nil;
}

#pragma mark - Public methods

- (void)resolve:(id)value {
   if (value == self)
      @throw [NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"future can't be resolved with self as resolving value"
                                   userInfo:nil];

   // Avoid a non pending future to transition to another state
   // (https://github.com/promises-aplus/promises-spec#promise-states)
   //
   // Also avoid a pending future waiting for its result to resolve (aka a future) to run resolve
   // once again
   // https://github.com/promises-aplus/promises-spec#the-promise-resolution-procedure (2.1)
   if (![self isStatePending] || self.result)
      return;

   self.result = value;
}

- (void)abort {
   self.state = RBFutureStateAborted;
}

- (BOOL)isStatePending {
   return self.state == RBFutureStatePending;
}

+ (BOOL)automaticallyNotifiesObserversOfResult {
   return NO;
}

- (void)setResult:(id<NSObject>)result {

   // Remove observer that may have been added previously on _result (see above)
   if ([_result isKindOfClass:RBFuture.class])
      [(RBFuture *)_result removeObserver:self forKeyPath:RBFuturePropertyState];

   [self willChangeValueForKey:@"_result"];
   _result = [result isKindOfClass:NSError.class] ? [RBErrorException exceptionWithError:(NSError *)result message:nil] : result;
   [self didChangeValueForKey:@"_result"];

   // Don't do anything if it's a future, just observe
   if ([_result isKindOfClass:RBFuture.class])
   {
      [(RBFuture *)_result addObserver:self
                             forKeyPath:RBFuturePropertyState
                                options:0
                                context:(__bridge void *)(RBFuturePropertyState)];
      // Manually trigger observing code (using NSKeyValueObservingOptionInitial is error prone in our case)
      [self _observeFuture:(RBFuture *)result];
   }
   else if ([_result isKindOfClass:NSException.class])
      self.state = RBFutureStateRejected;
   else
      self.state = RBFutureStateFulfilled;
}

- (id)result {
   return (self.state == RBFutureStatePending || self.state == RBFutureStateAborted) ? nil : _result;
}

- (void)setState:(RBFutureState)state {
   // Don't update if We are aleady on a final state (!= Pending)
   if (_state == state || _state != RBFutureStatePending)
      return;

   _state = state;
}

#pragma mark - Protected methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   // result_(aka a future) may have changed state
   if (context == (__bridge void *)(RBFuturePropertyState))
      [self _observeFuture:object];
}

- (void)_observeFuture:(RBFuture *)future {
   // future not yet resolved
   if ((future.state == RBFutureStatePending))
      return;

   self.result = future.result;
}

#pragma mark - Private methods

@end
