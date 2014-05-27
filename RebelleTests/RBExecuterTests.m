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
#import "RBActionSet.h"
#import "RBFuture.h"

SPEC_BEGIN(RBExecuterTests)

describe(@"test", ^{
   __block RBExecuter *executer;
   __block RBActionSet *actions;
   __block RBFuture  *future;

   beforeEach(^{
      actions = [RBActionSet mock];
      future = [RBFuture nullMock];

      executer = [RBExecuter executerWithActionSet:actions];
   });

   describe(@"callbacks", ^{
      it(@"call success", ^{
         [future stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [future stub:@selector(result) andReturn:@"Hello"];

         [executer execute:future];

         [[actions shouldEventually] receive:@selector(succeeded) andReturn:^NSString *(id value){ return nil; } withArguments:@"Hello"];
      });

      it(@"call catch", ^{
         NSException *exception = [NSException nullMock];

         [future stub:@selector(state) andReturn:theValue(RBFutureStateRejected)];
         [future stub:@selector(result) andReturn:exception];

         [executer execute:future];

         [[actions shouldEventually] receive:@selector(catched) andReturn:^NSException *(NSException *e){ return nil; } withArguments:exception];
      });

      it(@"call success with multiple arguments", ^{
         [future stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [future stub:@selector(result) andReturn:@[@"Hello", @"World"]];

         [executer execute:future];

         [[actions shouldEventually] receive:@selector(succeeded) andReturn:^(id arg1, id arg2) { return nil; } withArguments:@"Hello", @"World"];
      });

      it(@"call success with scalars", ^{

      });

      it(@"exception when block signature mismatch", ^{

      });
   });

   describe(@"result when", ^{
      it(@"returning value from callback", ^{
         [future stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [actions stub:@selector(succeeded) andReturn:^{ return @"Good result"; } ];

         [executer execute:future];

         [[expectFutureValue(executer.result) shouldEventually] equal:@"Good result"];
      });

      it(@"Throw an exception", ^{
         NSException *exception = [NSException nullMock];

         [future stub:@selector(state) andReturn:theValue(RBFutureStateFulfilled)];
         [actions stub:@selector(succeeded) andReturn:^{ @throw exception; return nil; }];

         [executer execute:future];

         [[expectFutureValue(executer.result) shouldEventually] equal:exception];
      });
   });
});

SPEC_END