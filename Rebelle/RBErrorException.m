//
// This file is part of Rebelle
//  
//  Created by JC on 9/10/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import "RBErrorException.h"

NSString *const RBErrorExceptionName = @"RBErrorException";

/// Private API
@interface RBErrorException ()
@property(nonatomic, strong)NSError *error;
@end

@implementation RBErrorException

#pragma mark - Ctor/Dtor

+ (instancetype)exceptionWithError:(NSError *)error message:(NSString *)message {
   return [[self alloc] initWithError:error message:message];
}

-(id)initWithError:(NSError *)error message:(NSString *)message {
   if (!(self = [super initWithName:RBErrorExceptionName reason:message userInfo:nil]))
      return nil;

   self.error = error;

   return self;
}

#pragma mark - Public methods

#pragma mark - Protected methods

#pragma mark - Private methods

@end
