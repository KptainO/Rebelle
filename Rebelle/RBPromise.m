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
#import "RBResolver.h"

NSString *const RBPromisePropertyState = @"state";
NSString *const RBPromisePropertyResolved = @"resolveState";

@interface RBPromise ()
// Public:
@property(nonatomic, assign)RBPromiseState      state;

// Private:
@property(nonatomic, assign)BOOL                isReady_;

@property(nonatomic, strong)NSMutableArray      *promises_;
@property(nonatomic, strong)RBExecuter          *executer_;
@property(nonatomic, strong)RBResolver          *resolver_;

@property(nonatomic, strong)RBActionSet         *action_;
@end

@implementation RBPromise

@synthesize executer_   = _executer;
@synthesize resolver_   = _resolver;
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
   self.executer_ = [RBExecuter new];
   self.resolver_ = [RBResolver new];

   self.action_ = [RBActionSet new];

   return self;
}

- (void)resolve:(id)value {
   // If we're receiving a RBPromise object, then resolve will indeed happen with its internal resolver object
   // (RBResolver should not be aware of the RBPromise Facade object)
   if ([value isKindOfClass:RBPromise.class])
      [self.resolver_ resolve:((RBPromise *)value).resolver_];
   else
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

- (RBHandlerThen)then {
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

- (RBHandlerOnSuccess)onSuccess {
   __weak typeof(self) this = self;

   if (!_onSuccess)
      _onSuccess = ^(RBPromiseFulfilled fulfilled) {
      this.action_.succeeded = fulfilled;

      return this;
   };

   return _onSuccess;
}

- (RBHandlerCatched)onCatch {
   __weak typeof(self) this = self;

   if (!_onCatch)
      _onCatch = ^(Class exceptionCatchClass, RBPromiseRejected catchAction) {
      [this.action_ setOnCatch:exceptionCatchClass do:catchAction];
      
      return this;
   };

   return _onCatch;
}

- (RBHandlerReady)ready {
   __weak typeof(self) this = self;

   if (!_ready)
      _ready = ^{
         this.isReady_ = YES;

         return this;
      };

   return _ready;
}

- (RBHandlerNext)next {
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

#pragma mark - Private methods

- (void)setIsReady_:(BOOL)isReady {
   if (isReady == _isReady)
      return;

   _isReady = isReady;

   [self _executeIfNeeded];
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

- (void)_executeIfNeeded {
   if (!self.isReady_)
      return;

   if (!self.executer_.executed)
   {
      if (self.resolver_.state == RBPromiseStateFulfilled)
         [self.executer_ execute:self.action_.succeeded withValue:self.resolver_.result];
      else if (self.resolver_.state == RBPromiseStateRejected)
         [self.executer_ execute:self.action_.catched withValue:self.resolver_.result];
   }
}

@end
