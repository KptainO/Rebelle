//
// This file is part of Rebelle
//  
//  Created by JC on 8/12/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Foundation/Foundation.h>

@protocol RBThenable;

typedef id(^RBPromiseFulfilled)(id value);
typedef id(^RBPromiseRejected)(id reason);

typedef id<RBThenable>(^RBThenableThen)(RBPromiseFulfilled onFulfilled, RBPromiseRejected onRejected);

/**
 * Define a compliant interface with Promises/A+
 * (https://github.com/promises-aplus/promises-spec)
 * It contain only necessary element so that different Promise implementations would be compatible anyway
 */
@protocol RBThenable <NSObject>

@property(nonatomic, copy, readonly)RBThenableThen then;

- (void)resolve:(id)value;

@end