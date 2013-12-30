//
// This file is part of Rebelle
//  
// Created by JC on 12/6/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBResolver.h"

#import "RBErrorException.h"

NSString *const RBResolverPropertyState = @"state";

// Private API
@interface RBResolver ()
@property(nonatomic, assign)RBResolverState     state;
@property(nonatomic, strong)id                  result;
@end

@implementation RBResolver

#pragma mark - Ctor/Dtor

- (void)dealloc {
   self.result = nil;
}

#pragma mark - Public methods

- (void)resolve:(id)value {
   if (value == self)
      @throw [NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"resolver can't be resolved with self as resolving value"
                                   userInfo:nil];

   // Avoid a non pending resolver to transition to another state
   // (https://github.com/promises-aplus/promises-spec#promise-states)
   //
   // Also avoid a pending resolver waiting for its result to resolve (aka a resolver) to run resolve
   // once again
   // https://github.com/promises-aplus/promises-spec#the-promise-resolution-procedure (2.1)
   if (![self isStatePending] || self.result)
      return;

   self.result = value;
}

- (BOOL)isStatePending {
   return self.state == RBResolverStatePending;
}

+ (BOOL)automaticallyNotifiesObserversOfResult {
   return NO;
}

- (void)setResult:(id<NSObject>)result {

   // Remove observer that may have been added previously on _result (see above)
   if ([_result isKindOfClass:RBResolver.class])
      [(RBResolver *)_result removeObserver:self forKeyPath:RBResolverPropertyState];

   [self willChangeValueForKey:@"_result"];
   _result = [result isKindOfClass:NSError.class] ? [RBErrorException exceptionWithError:(NSError *)result message:nil] : result;
   [self didChangeValueForKey:@"_result"];

   // Don't do anything if it's a resolver, just observe
   if ([_result isKindOfClass:RBResolver.class])
   {
      [(RBResolver *)_result addObserver:self
                             forKeyPath:RBResolverPropertyState
                                options:0
                                context:(__bridge void *)(RBResolverPropertyState)];
      // Manually trigger observing code (using NSKeyValueObservingOptionInitial is error prone in our case)
      [self _observeResolver:(RBResolver *)result];
   }
   else if ([result isKindOfClass:NSException.class])
      self.state = RBResolverStateRejected;
   else
      self.state = RBResolverStateFulfilled;
}

- (void)setState:(RBResolverState)state {
   // Don't update if We are aleady on a final state (!= Pending)
   if (_state == state || _state != RBResolverStatePending)
      return;

   _state = state;
}

#pragma mark - Protected methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   // result_(aka a resolver) may have changed state
   if (context == (__bridge void *)(RBResolverPropertyState))
      [self _observeResolver:object];
}

- (void)_observeResolver:(RBResolver *)resolver {
   // resolver not yet resolved
   if ((resolver.state == RBResolverStatePending))
      return;

   self.result = resolver.result;
}

#pragma mark - Private methods

@end
