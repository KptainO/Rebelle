//
// This file is part of Rebelle
//  
//  Created by JC on 9/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Foundation/Foundation.h>

@class RBActionSet;
@protocol RBFuture;

#import "RBThenable.h"

extern NSString   *const RBExecuterExecutedProperty;
extern NSString   *const RBExecuterCanceledProperty;

typedef id(^ExecuteCallback)(id value);

/**
 * Handle promise block invocation. It ensure that
 * - block is invoked on correct thread
 * - block is invoked only once (if using this class of course)
 * - that any thrown exceptions from block are catched the proper way
 */
@interface RBExecuter : NSObject

@property(nonatomic, assign, readonly)BOOL   executed;
@property(nonatomic, assign, readonly)BOOL   canceled;
@property(nonatomic, strong, readonly)id     result;

+ (instancetype)executerWithActionSet:(RBActionSet *)actionSet;
- (instancetype)initWithActionSet:(RBActionSet *)actionSet;

+ (id)new UNAVAILABLE_ATTRIBUTE;
- (id)init UNAVAILABLE_ATTRIBUTE;

- (void)execute:(id<RBFuture>)future;

- (void)cancel;

@end


/// Contain all selectors that are considered as protected
/// **MUST** not be used by others
@interface RBExecuter (Protected)
- (void)_execute:(id<RBFuture>)future;
@end
