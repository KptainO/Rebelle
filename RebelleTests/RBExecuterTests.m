//
// This file is part of Rebelle
//  
//  Created by JC on 10/27/13.
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code
//

#import <SenTestingKit/SenTestingKit.h>
#import <Kiwi.h>

#import "RBPromise.h"
#import "RBExecuter.h"

SPEC_BEGIN(RBExecuterTests)

describe(@"test", ^{
   __block RBExecuter *executer;

   beforeEach(^{
      executer = [RBExecuter new];
   });

   describe(@"result when", ^{
      it(@"returning NIL from callback", ^{
         [executer execute:^id(id value){ return nil; } withValue:@"Hello World"];

         [[expectFutureValue(executer.result) shouldEventually] beNil];
      });

      it(@"callback is NIL", ^{
         [executer execute:nil withValue:@"Hello World"];

         [[expectFutureValue(executer.result) shouldEventually] equal:@"Hello World"];
      });

      it(@"returning value from callback", ^{
         [executer execute:^id(id value) { return @"Good result"; } withValue:@"Wrong result"];

         [[expectFutureValue(executer.result) shouldEventually] equal:@"Good result"];
      });

      it(@"Throw an exception", ^{
         NSException *exception = [NSException exceptionWithName:@"FakeException" reason:nil userInfo:nil];
         [executer execute:^id(id value) { @throw exception; return nil; } withValue:nil];

         [[expectFutureValue(executer.result) shouldEventually] equal:exception];
      });
   });
});

SPEC_END