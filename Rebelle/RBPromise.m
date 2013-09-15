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

@property(nonatomic, strong)NSObject         *result_;

@property(nonatomic, strong)NSMutableArray   *promises_;
@property(nonatomic, copy)RBPromiseFulfilled onFulfilled_;
@property(nonatomic, copy)RBPromiseRejected  onRejected_;

@property(nonatomic, strong)RBExecuter       *executer_;

@end

@implementation RBPromise

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
         [promise resolve:this.result_];

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

   if ([value isKindOfClass:[RBPromise class]])
      return [value addObserver:self
                     forKeyPath:RBPromisePropertyResolved
                        options:NSKeyValueObservingOptionInitial
                        context:(__bridge void *)(RBPromisePropertyState)];

   if ([value isKindOfClass:[NSException class]])
      [self _reject:(NSException *)value];
   else if ([value isKindOfClass:[NSError class]])
      [self _reject:[RBErrorException exceptionWithError:value message:nil]];
   else
      [self _fulfill:value];
}

+ (NSSet *)keyPathsForValuesAffectingResolved {
   return [NSSet setWithArray:@[@"state"]];
}

- (BOOL)isResolved {
   return ![self isStatePending] && self.executer_.executed;
}

- (BOOL)isStatePending {
   return self.state == RBPromiseStatePending;
}

#pragma mark - Protected methods

- (void)_fulfill:(id)value {
   self.state = RBPromiseStateFulfilled;
   
   [self.executer_ execute:self.onFulfilled_ withValue:value];
}

- (void)_reject:(NSException *)reason {
   self.state = RBPromiseStateRejected;
   
   [self.executer_ execute:self.onRejected_ withValue:reason];
}

#pragma mark - Private methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   if (context == (__bridge void *)(RBExecuterExecutedProperty))
   {
      [self willChangeValueForKey:RBPromisePropertyResolved];
      [self didChangeValueForKey:RBPromisePropertyResolved];

      for (RBPromise *promise in self.promises_)
         [promise resolve:self.executer_.result];

      return;
   }

   RBPromise *promise = object;

   // Promise not yet resolved
   if (![promise isResolved])
      return;

   [self.result_ removeObserver:self forKeyPath:RBPromisePropertyResolved];
      
   if (promise.state == RBPromiseStateRejected)
      [self _reject:(NSException *)promise.result_];
   else
      [self _fulfill:promise.result_];
}

@end
