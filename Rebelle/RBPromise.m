//
// This file is part of Rebelle
//
//  Created by JC on 8/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBPromise.h"

#import "RBExecuter.h"
#import "RBActionSet.h"
#import "RBFuture.h"

NSString *const RBPromisePropertyState = @"state";
NSString *const RBPromisePropertyResolved = @"resolveState";

/**
 * Keep alive promises while executing their RBExecuter content
 */
static NSMutableSet *asyncExecuterPromisesTasks = nil;

@interface RBPromise ()
// Public:
@property(nonatomic, assign)RBPromiseState      state;

// Private:
@property(nonatomic, assign)BOOL                isReady_;

@property(nonatomic, strong)NSMutableArray      *promises_;
@property(nonatomic, strong)RBExecuter          *executer_;
@property(nonatomic, strong)RBFuture            *future_;

@property(nonatomic, strong)RBActionSet         *action_;
@end

@implementation RBPromise

@synthesize executer_   = _executer;
@synthesize future_   = _future;
@synthesize isReady_    = _isReady;

@synthesize then        = _then;
@synthesize onSuccess   = _onSuccess;
@synthesize onCatch     = _onCatch;
@synthesize ready       = _ready;
@synthesize next        = _next;

- (id)init {
   if (!(self = [super init]))
      return nil;

   self.promises_ = [NSMutableArray new];
   self.action_ = [RBActionSet new];
   self.future_ = [RBFuture new];
   self.executer_ = [RBExecuter executerWithActionSet:self.action_];

   // To ensure callbacks are called in-time, promise must be marked as "ready"
   // To ease programmer life who might forget to call ready(), we do it automatically after a short delay
   [self performSelector:@selector(_autoReady) withObject:nil afterDelay:0.2];

   return self;
}

- (void)dealloc {
   self.future_ = nil;
   self.executer_ = nil;
}

- (void)resolve:(id)value {
   // If we're receiving a RBPromise object, then resolve will indeed happen with its internal future object
   // (RBFuture should not be aware of the RBPromise Facade object)
   if ([value isKindOfClass:RBPromise.class])
      [self.future_ resolve:((RBPromise *)value).future_];
   else
      [self.future_ resolve:value];
}

- (void)cancel {
   /// Recursive abort
   for (RBPromise *promise in self.promises_)
      [promise abort];
}

- (void)abort {
   self.state = RBPromiseStateAborted;

   [self cancel];
}

- (RBThenablePlusThen)then {
   __weak typeof(self) this = self;

   if (_then)
      return _then;

   // Define "then" block which will be called each time user do promise.then()
   // It basically call next() + define success/failure callbacks
   _then = ^(RBPromiseFulfilled onFulfilled, RBPromiseRejected onRejected) {

      return this.next()
      .onSuccess(onFulfilled)
      .onCatch(NSException.class, onRejected)
      .ready();
   };

   return _then;
}

- (RBThenablePlusOnSuccess)onSuccess {
   __weak typeof(self) this = self;

   if (!_onSuccess)
      _onSuccess = ^(RBPromiseFulfilled fulfilled) {
      this.action_.succeeded = fulfilled;

      return this;
   };

   return _onSuccess;
}

- (RBThenablePlusCatched)onCatch {
   __weak typeof(self) this = self;

   if (!_onCatch)
      _onCatch = ^(Class exceptionCatchClass, RBPromiseRejected catchAction) {
      [this.action_ setCatched:exceptionCatchClass do:catchAction];
      
      return this;
   };

   return _onCatch;
}

- (RBThenablePlusReady)ready {
   __weak typeof(self) this = self;

   if (!_ready)
      _ready = ^{
         this.isReady_ = YES;

         return this;
      };

   return _ready;
}

- (RBThenablePlusNext)next {
   __weak typeof(self) this = self;

   if (_next)
      return _next;

   _next = ^ {
      RBPromise *promise = [RBPromise new];

      // Mark current promise as ready
      this.ready();

      // Then add the new one as child and return it to user
      [this.promises_ addObject:promise];

      // If our current promise is already resolved, then launch our new promise resolution
      // procedure (otherwise it won't never be called automatically)
      if ([this isResolved])
         [promise resolve:this.executer_.result];

      return promise;
   };

   return _next;
}

- (BOOL)isResolved {
   return self.executer_.executed;
}

- (void)setState:(RBPromiseState)state {
   // Don't update if We are aleady on a final state (!= Pending)
   if (_state == state || _state != RBPromiseStatePending)
      return;

   _state = state;

   [self _executeIfNeeded];
}

#pragma mark - Protected methods

- (void)setFuture_:(RBFuture *)future {
   if (future == _future)
      return;

   [_future removeObserver:self
                  forKeyPath:RBFuturePropertyState];

   _future = future;

   [_future addObserver:self
               forKeyPath:RBFuturePropertyState
                  options:0
                  context:(__bridge void *)(RBFuturePropertyState)];
}

- (void)setExecuter_:(RBExecuter *)executer {
   if (executer == _executer)
      return;

   [_executer removeObserver:self
                  forKeyPath:RBExecuterExecutedProperty];
   [_executer removeObserver:self
                  forKeyPath:RBExecuterCanceledProperty];

   _executer = executer;

   [_executer addObserver:self
               forKeyPath:RBExecuterExecutedProperty
                  options:0
                  context:(__bridge void *)(RBExecuterExecutedProperty)];
   [_executer addObserver:self
               forKeyPath:RBExecuterCanceledProperty
                  options:0
                  context:(__bridge void *)(RBExecuterCanceledProperty)];
}

#pragma mark - Private methods

- (void)setIsReady_:(BOOL)isReady {
   if (isReady == _isReady)
      return;

   _isReady = isReady;

   [self _executeIfNeeded];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   if (context == (__bridge void *)(RBExecuterCanceledProperty))
   {
      [self _removeAsyncExecuteTask];
   }
   // Executer finished execution
   if (context == (__bridge void *)(RBExecuterExecutedProperty))
   {
      [self willChangeValueForKey:RBPromisePropertyResolved];
      [self didChangeValueForKey:RBPromisePropertyResolved];

      for (RBPromise *promise in self.promises_)
         [promise resolve:self.executer_.result];

      [self _removeAsyncExecuteTask];

      return;
   }
   else if (context == (__bridge void *)(RBFuturePropertyState))
      [self _observeFutureState];
}

- (void)_observeFutureState {
   if (self.future_.state == RBPromiseStateFulfilled)
      self.state = RBPromiseStateFulfilled;
   else if (self.future_.state == RBPromiseStateRejected)
      self.state = RBPromiseStateRejected;
}

- (void)_executeIfNeeded {
   if (!self.isReady_ || self.state == RBPromiseStatePending)
      return;

   [self _addAsyncExecuteTask];

   if (self.state == RBPromiseStateAborted)
      return [self.executer_ cancel];

   [self.executer_ execute:self.future_];
}

- (void)_autoReady {
   self.ready();
}

- (void)_addAsyncExecuteTask {
   if (!asyncExecuterPromisesTasks)
      asyncExecuterPromisesTasks = [NSMutableSet new];

   [asyncExecuterPromisesTasks addObject:self];
}

- (void)_removeAsyncExecuteTask {
   [asyncExecuterPromisesTasks removeObject:self];
}

@end
