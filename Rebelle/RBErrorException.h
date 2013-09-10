//
// This file is part of Rebelle
//  
//  Created by JC on 9/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <Foundation/Foundation.h>

extern NSString *const RBErrorExceptionName;

/**
 * This is an exception that wrap a NSError object
 */
@interface RBErrorException : NSException

@property(nonatomic, strong, readonly)NSError   *error;

+ (instancetype)exceptionWithError:(NSError *)error message:(NSString *)message;
- (id)initWithError:(NSError *)error message:(NSString *)message;

@end


/// Contain all selectors that are considered as protected
/// **MUST** not be used by others
@interface RBErrorException (Protected)
@end
