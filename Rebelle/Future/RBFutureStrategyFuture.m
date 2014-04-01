//
// This file is part of Rebelle
//  
// Created by JC on 3/21/14.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBFutureStrategyFuture.h"

#import "RBFuture.h"
#import "RBFutureArray.h"

// Private API
@interface RBFutureStrategyFuture ()
@property(nonatomic, assign, getter = isArrayOfFutures_)BOOL   arrayOfFutures_;
@property(nonatomic, strong)NSArray                            *futures_;
@property(nonatomic, strong)NSMutableArray                     *results_;
@property(nonatomic, assign)NSUInteger                         resultsResolvedCount_;
@end

@implementation RBFutureStrategyFuture

@synthesize futures_ = _futures;

#pragma mark - Ctor/Dtor

- (void)dealloc {
   // Force setter use
   self.futures_ = nil;
}

#pragma mark - Public methods

+ (BOOL)accept:(id)value {
   return [value conformsToProtocol:@protocol(RBFuture)] || [value isKindOfClass:RBFutureArray.class];
}

- (void)compute:(id)value {
   self.arrayOfFutures_ = [value isKindOfClass:RBFutureArray.class];
   self.futures_ = self.isArrayOfFutures_ ? value : @[value];
}

#pragma mark - Protected methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   // result_(aka a future) may have changed state
   if (context == (__bridge void *)(RBFuturePropertyState))
      [self _observeFuture:object];
}

- (void)_observeFuture:(id<RBFuture>)future {
   NSUInteger index = 0;

   // future not yet resolved
   if (!future || future.state == RBFutureStatePending)
      return;
   // future rejected => final result rejected result
   if (future.state == RBFutureStateRejected)
      return [self _computationDone:future.result];

   index = [self.futures_ indexOfObject:future];

   if ([self.results_[index] isKindOfClass:NSNull.class])
   {
      self.results_[index] = future.result ?: [NSNull null];
      self.resultsResolvedCount_ += 1;

      // All futures resolved
      if (self.resultsResolvedCount_ == self.futures_.count)
         [self _computationDone:self.isArrayOfFutures_ ? self.results_ : self.results_[0]];
   }
}

- (void)_computationDone:(id)result {
   self.futures_ = nil;

   [[NSNotificationCenter defaultCenter] postNotificationName:@"RBComputationDoneNotification"
                                                       object:self
                                                     userInfo:@{ @"result": result ?: [NSNull null] }];
}

- (void)setFutures_:(NSArray *)futures {
   if (futures == _futures)
      return;

   for (NSObject<RBFuture> *future in _futures) {
      [future removeObserver:self forKeyPath:RBFuturePropertyState];
   }

   _futures = futures;
   self.resultsResolvedCount_ = 0;
   self.results_ = [NSMutableArray arrayWithCapacity:futures.count];

   for (NSObject<RBFuture> *future in _futures) {
      // Insert inital result: "nil"
      [self.results_ addObject:[NSNull null]];

      [future addObserver:self
               forKeyPath:RBFuturePropertyState
                  options:0
                  context:(__bridge void *)(RBFuturePropertyState)];
      // Manually trigger observing code (using NSKeyValueObservingOptionInitial is error prone in our case)
      [self _observeFuture:future];
   }
}

#pragma mark - Private methods

@end
