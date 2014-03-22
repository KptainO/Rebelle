//
// This file is part of Rebelle
//  
// Created by JC on 12/6/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBFuture.h"

#import "RBErrorException.h"
#import "RBFutureStrategy.h"
#import "RBFutureStrategyFactory.h"

NSString *const RBFuturePropertyState = @"state";

// Private API
@interface RBFuture ()
@property(nonatomic, assign)RBFutureState          state;
@property(nonatomic, strong)id                     result;

@property(nonatomic, strong)id                     computingResult_;
@property(nonatomic, strong)id<RBFutureStrategy>   strategy_;
@end

@implementation RBFuture

@synthesize result            = _result;
@synthesize strategy_         = _strategy;

#pragma mark - Ctor/Dtor

- (void)dealloc {
   // Force setter use
   self.strategy_ = nil;
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
   if (![self isStatePending] || self.computingResult_)
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
   self.computingResult_ = nil;
   self.strategy_ = [RBFutureStrategyFactory create:result];

   if (self.strategy_)
   {
      self.computingResult_ = result;
      return [self.strategy_ compute:result];
   }

   [self willChangeValueForKey:@"result"];
   _result = [result isKindOfClass:NSError.class] ? [RBErrorException exceptionWithError:(NSError *)result message:nil] : result;
   [self didChangeValueForKey:@"result"];

   if ([_result isKindOfClass:NSException.class])
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

- (void)setStrategy_:(id<RBFutureStrategy>)strategy {
   if (strategy == _strategy)
      return;

   if (_strategy)
      [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_strategy];
   _strategy = strategy;
   if (_strategy)
   {
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(_onStrategyComputed:)
                                                   name:@"RBComputationDoneNotification"
                                                 object:_strategy];
   }
}

- (void)_onStrategyComputed:(NSNotification *)notification {
   id result = notification.userInfo[@"result"];

   self.result = [result isKindOfClass:NSNull.class] ? nil : result;
}

#pragma mark - Private methods

@end
