//
// This file is part of Rebelle
//  
//  Created by JC on 8/12/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Foundation/Foundation.h>

@protocol RBThenable;

typedef void *(^RBPromiseFulfilled)(id value);
typedef void *(^RBPromiseRejected)(id reason);
typedef id<RBThenable>(^RBThenableThen)(RBPromiseFulfilled onFulfilled, RBPromiseRejected onRejected);

/**
 * Only define "then" block attribute
 */
@protocol RBThenable <NSObject>

@property(nonatomic, copy, readonly)RBThenableThen then;

@end