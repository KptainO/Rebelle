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
#import "RBAction.h"

NSString *const RBPromisePropertyState = @"state";
NSString *const RBPromisePropertyResolved = @"resolved";

@interface RBPromise ()
// Public:
@property(nonatomic, copy)RBPromiseThenableThen  then;
@property(nonatomic, assign)RBPromiseState   state;

// Private:
@property(nonatomic, strong)id<NSObject>     result_;

@property(nonatomic, strong)NSMutableArray   *promises_;
@property(nonatomic, strong)RBExecuter       *executer_;
@property(nonatomic, strong)RBAction         *action_;

@end

@implementation RBPromise

@synthesize result_     = result_;
@synthesize executer_   = _executer;
@synthesize onSuccess   = _onSuccess;
@synthesize onCatch     = _onCatch;

@dynamic resolved;

- (id)init {
   if (!(self = [super init]))
      return nil;

   __block typeof(self) this = self;

   self.promises_ = [NSMutableArray new];
   self.executer_ = [RBExecuter new];
   self.action_ = [RBAction new];

   // Define "then" block which will be called each time user do promise.then()
   // It save defined blocks + associated generated promise
   self.then = ^RBPromise *(RBPromiseFulfilled onFulfilled, RBPromiseRejected onRejected) {
      RBPromise *promise = [RBPromise new];

      promise.onSuccess(onFulfilled);
      promise.onCatch(NSException.class, onRejected);
      
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

- (RBActionableOnSuccess)onSuccess {
   __weak typeof(self) this = self;

   if (!_onSuccess)
      _onSuccess = ^(RBPromiseFulfilled fulfilled) {
      this.action_.succeeded = fulfilled;

      return this;
   };

   return _onSuccess;
}

- (RBActionableCatched)onCatch {
   __weak typeof(self) this = self;

   if (!_onCatch)
      _onCatch = ^(Class exceptionCatchClass, RBPromiseRejected catchAction) {
      [this.action_ setOnCatch:exceptionCatchClass do:catchAction];
      
      return this;
   };

   return _onCatch;
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
      [self.executer_ execute:self.action_.succeeded withValue:self.result_];
   else if (state == RBPromiseStateRejected)
      [self.executer_ execute:self.action_.catched withValue:self.result_];
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
