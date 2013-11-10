//
// This file is part of Rebelle
//
//  Created by JC on 8/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBPromise.h"

#import "RBErrorException.h"

#import "RBExecuter.h"

NSString *const RBPromisePropertyState = @"state";
NSString *const RBPromisePropertyResolved = @"resolved";

@interface RBPromise ()
@property(nonatomic, copy)RBThenableThen     then;
@property(nonatomic, assign)RBPromiseState   state;

@property(nonatomic, strong)id<NSObject>         result_;

@property(nonatomic, strong)NSMutableArray   *promises_;
@property(nonatomic, copy)RBPromiseFulfilled onFulfilled_;
@property(nonatomic, copy)RBPromiseRejected  onRejected_;

@property(nonatomic, strong)RBExecuter       *executer_;

@end

@implementation RBPromise

@synthesize result_ = result_;

@dynamic resolved;

- (id)init {
   if (!(self = [super init]))
      return nil;

   __block typeof(self) this = self;

   self.promises_ = [NSMutableArray new];
   self.executer_ = [RBExecuter new];
   
   [self.executer_ addObserver:self forKeyPath:RBExecuterExecutedProperty
                       options:0
                       context:(__bridge void *)(RBExecuterExecutedProperty)];


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

- (void)dealloc {
   [self.executer_ removeObserver:self forKeyPath:@"executed"];
}

- (void)resolve:(id)value {
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
   return ![self isStatePending] && self.state != RBPromiseStateAborted && self.executer_.executed;
}

- (BOOL)isStatePending {
   return self.state == RBPromiseStatePending;
}

- (void)setState:(RBPromiseState)state {
   // Don't update if We are aleady on a final state (!= Pending)
   if (_state == state || _state != RBPromiseStatePending)
      return;

   _state = state;

   if (state == RBPromiseStateFulfilled)
      [self.executer_ execute:self.onFulfilled_ withValue:self.result_];
   else if (state == RBPromiseStateRejected)
      [self.executer_ execute:self.onRejected_ withValue:self.result_];
}

+ (BOOL)automaticallyNotifiesObserversOfResult_ {
   return NO;
}

- (void)setResult_:(id<NSObject>)result {

   // Remove observer that may have been added previously on result_ (see above)
   if ([result_ isKindOfClass:RBPromise.class])
      [(RBPromise *)result_ removeObserver:self forKeyPath:RBPromisePropertyResolved];

   [self willChangeValueForKey:@"result_"];
   result_ = [result isKindOfClass:NSError.class] ? [RBErrorException exceptionWithError:(NSError *)result message:nil] : result;
   [self didChangeValueForKey:@"result_"];

   // Don't do anything if it's a RBPromise, just observe
   if ([result_ isKindOfClass:RBPromise.class])
   {
      [(RBPromise *)result_ addObserver:self
                            forKeyPath:RBPromisePropertyResolved
                               options:0
                               context:(__bridge void *)(RBPromisePropertyResolved)];
      // Manually trigger observing code (using NSKeyValueObservingOptionInitial is error prone in our case)
      [self _observePromiseResolve:(RBPromise *)result];
   }
   else if ([result isKindOfClass:NSException.class])
      self.state = RBPromiseStateRejected;
   else
      self.state = RBPromiseStateFulfilled;
}

#pragma mark - Private methods

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
   // else result_(aka a Promise) maybe changed state
   else if (context == (__bridge void *)(RBPromisePropertyResolved))
      [self _observePromiseResolve:object];
}

- (void)_observePromiseResolve:(RBPromise *)promise {
   // Promise not yet resolved
   if (![promise isResolved])
      return;

   self.result_ = promise.result_;
}

@end
