//
// This file is part of Rebelle
//  
//  Created by JC on 8/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Foundation/Foundation.h>

#import "RBThenable.h"

typedef enum {
   RBPromiseStatePending,
   RBPromiseStateFulfilled,
   RBPromiseStateRejected
} RBPromiseState;

/**
 * Thenable promise
 * - Call "then" if you want to define actions to occur once promise has been resolved
 * - Call ::resolve: to start promise resolving procedure.
 *
 * You can chain calls to then to define multiple promises which must occur after the previous
 * one was realized.
 * \code promise.then(loadUserBlock, nil).then(loadUserLastTweetsBlock, nil) etc. \endcode
 */
@interface RBPromise : NSObject<RBThenable>

@property(nonatomic, copy, readonly)RBThenableThen then;

- (void)resolve:(id)value;

@end
