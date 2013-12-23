//
// This file is part of Rebelle
//
// Created by JC on 11/27/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBActionSet.h"

// Private API
@interface RBActionSet ()
@property(nonatomic, strong)NSMutableArray *exceptionAction_;
@property(nonatomic, strong)NSMutableArray *exceptionCatchClasses_;
@end

@implementation RBActionSet

#pragma mark - Ctor/Dtor

- (id)init {
   if (!(self = [super init]))
      return nil;

   self.exceptionAction_ = [NSMutableArray new];
   self.exceptionCatchClasses_ = [NSMutableArray new];

   return self;
}

#pragma mark - Public methods

- (void)setSucceeded:(RBPromiseFulfilled)succeeded {
   if (_succeeded)
      return;

   _succeeded = succeeded;
}

- (void)setOnCatch:(Class)exceptionCatchClass do:(RBPromiseRejected)action {
   if (!action)
      action = ^id(NSException *exception) { return nil; };

      if (![self.exceptionCatchClasses_ containsObject:exceptionCatchClass])
      {
         [self.exceptionCatchClasses_ addObject:exceptionCatchClass];
         [self.exceptionAction_ addObject:[action copy]];
      }
}

- (RBPromiseRejected)catched {
   return ^id(NSException *reason) {
      RBPromiseRejected rejected = [self _actionForException:reason];

      return rejected(reason);
   };
}

#pragma mark - Protected methods

- (RBPromiseRejected)_actionForException:(NSException *)exception {
   for (int i = 0; i < self.exceptionCatchClasses_.count; ++i)
   {
      if ([exception isKindOfClass:self.exceptionCatchClasses_[i]])
         return self.exceptionAction_[i];
   }

   return ^id(NSException *reason) { return reason; };
}

#pragma mark - Private methods

@end
