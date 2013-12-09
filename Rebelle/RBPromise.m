//
// This file is part of Rebelle
//
//  Created by JC on 8/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBPromise.h"

#import "RBExecuter.h"
#import "RBResolver.h"

NSString *const RBPromisePropertyState = @"state";
NSString *const RBPromisePropertyResolved = @"resolved";

@interface RBPromise ()
// Public:
@property(nonatomic, copy)RBThenableThen     then;
@property(nonatomic, assign)RBPromiseState   state;

// Private:
@property(nonatomic, strong)NSMutableArray   *promises_;
@property(nonatomic, copy)RBPromiseFulfilled onFulfilled_;
@property(nonatomic, copy)RBPromiseRejected  onRejected_;

@property(nonatomic, strong)RBExecuter       *executer_;
@property(nonatomic, strong)RBResolver       *resolver_;
@end

@implementation RBPromise

@synthesize executer_   = _executer;
@synthesize resolver_   = _resolver;

@dynamic resolved;

- (id)init {
   if (!(self = [super init]))
      return nil;

   __block typeof(self) this = self;

   self.promises_ = [NSMutableArray new];
   self.executer_ = [RBExecuter new];
   self.resolver_ = [RBResolver new];

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
         [promise resolve:this.executer_.result];

      return promise;
   };

   return self;
}

- (void)resolve:(id)value {
   [self.resolver_ resolve:value];
}

- (void)cancel {
   /// Recursive abort
   for (RBPromise *promise in self.promises_)
      [promise abort];
}

- (void)abort {
   self.state = RBPromiseStateAborted;

   [self.executer_ cancel];
   [self cancel];
}

+ (NSSet *)keyPathsForValuesAffectingResolved {
   return [NSSet setWithArray:@[@"state"]];
}

- (BOOL)isResolved {
   return self.state != RBPromiseStatePending && self.state != RBPromiseStateAborted && self.executer_.executed;
}

- (void)setState:(RBPromiseState)state {
   // Don't update if We are aleady on a final state (!= Pending)
   if (_state == state || _state != RBPromiseStatePending)
      return;

   _state = state;

   if (state == RBPromiseStateFulfilled)
      [self.executer_ execute:self.onFulfilled_ withValue:self.resolver_.result];
   else if (state == RBPromiseStateRejected)
      [self.executer_ execute:self.onRejected_ withValue:self.resolver_.result];
}

#pragma mark - Protected methods

- (void)setResolver_:(RBResolver *)resolver {
   if (resolver == _resolver)
      return;

   [_resolver removeObserver:self
                  forKeyPath:RBResolverPropertyState];

   _resolver = resolver;

   [_resolver addObserver:self
               forKeyPath:RBResolverPropertyState
                  options:0
                  context:(__bridge void *)(RBResolverPropertyState)];
}

#pragma mark - Private methods

- (void)setExecuter_:(RBExecuter *)executer {
   if (executer == _executer)
      return;

   [_executer removeObserver:self
                  forKeyPath:RBExecuterExecutedProperty];

   _executer = executer;

   [_executer addObserver:self
               forKeyPath:RBExecuterExecutedProperty
                  options:0
                  context:(__bridge void *)(RBExecuterExecutedProperty)];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   // Executer finished execution
   if (context == (__bridge void *)(RBExecuterExecutedProperty))
   {
      [self willChangeValueForKey:RBPromisePropertyResolved];
      [self didChangeValueForKey:RBPromisePropertyResolved];

      for (RBPromise *promise in self.promises_)
         [promise resolve:self.executer_.result];

      return;
   }
   else if (context == (__bridge void *)(RBResolverPropertyState))
      [self _observeResolverState];
}

- (void)_observeResolverState {
   if (self.resolver_.state == RBPromiseStateFulfilled)
      self.state = RBPromiseStateFulfilled;
   else if (self.resolver_.state == RBPromiseStateRejected)
      self.state = RBPromiseStateRejected;
}

@end
