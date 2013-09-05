//
// This file is part of Rebelle
//  
//  Created by JC on 8/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Foundation/Foundation.h>

@interface RBPromiseRejection : NSObject

@property(nonatomic, strong, readonly)NSException *exception;
@property(nonatomic, strong, readonly)NSError     *error;

- (BOOL)isError;
- (BOOL)isException;

@end
