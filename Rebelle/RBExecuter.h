//
// This file is part of Rebelle
//  
//  Created by JC on 9/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Foundation/Foundation.h>

#import "RBThenable.h"

extern NSString   *const RBExecuterExecutedProperty;

typedef id(^ExecuteCallback)(id value);


@interface RBExecuter : NSObject

@property(nonatomic, assign, readonly)BOOL   executed;
@property(nonatomic, strong, readonly)id     result;

- (void)execute:(ExecuteCallback)callback withValue:(id)value;

@end


/// Contain all selectors that are considered as protected
/// **MUST** not be used by others
@interface RBExecuter (Protected)


@end
