//
// This file is part of Rebelle
//  
// Created by JC on 3/21/14.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBFutureStrategyFuture.h"

#import "RBFuture.h"

// Private API
@interface RBFutureStrategyFuture ()
@property(nonatomic, strong)id<RBFuture>  future_;
@end

@implementation RBFutureStrategyFuture

@synthesize future_ = _future;

#pragma mark - Ctor/Dtor

- (void)dealloc {
   // Force setter use
   self.future_ = nil;
}

#pragma mark - Public methods

+ (BOOL)accept:(id)value {
   return [value conformsToProtocol:@protocol(RBFuture)];
}

- (void)compute:(id<RBFuture>)value {
   self.future_ = value;
}

#pragma mark - Protected methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   // result_(aka a future) may have changed state
   if (context == (__bridge void *)(RBFuturePropertyState))
      [self _observeFuture];
}

- (void)_observeFuture {
   // future not yet resolved
   if ((self.future_.state == RBFutureStatePending))
      return;

   id result = self.future_.result;

   self.future_ = nil;
   [[NSNotificationCenter defaultCenter] postNotificationName:@"RBComputationDoneNotification"
                                                       object:self
                                                     userInfo:@{ @"result": result ?: [NSNull null] }];
}

- (void)setFuture_:(id<RBFuture>)future {
   if (future == _future)
      return;

   [(NSObject *)_future removeObserver:self forKeyPath:RBFuturePropertyState];
   _future = future;
   [(NSObject<RBFuture> *)_future addObserver:self
                                        forKeyPath:RBFuturePropertyState
                                           options:0
                                           context:(__bridge void *)(RBFuturePropertyState)];
   // Manually trigger observing code (using NSKeyValueObservingOptionInitial is error prone in our case)
   [self _observeFuture];
}

#pragma mark - Private methods

@end
