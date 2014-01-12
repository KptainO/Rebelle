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
#import "RBResolver.h"

SPEC_BEGIN(RBExecuterTests)

describe(@"test", ^{
   __block RBExecuter *executer;
   __block RBActionSet *actions;
   __block RBResolver  *resolver;

   beforeEach(^{
      actions = [RBActionSet mock];
      resolver = [RBResolver nullMock];

      executer = [RBExecuter executerWithActionSet:actions];
   });

   describe(@"callbacks", ^{
      it(@"call success", ^{
         [resolver stub:@selector(state) andReturn:theValue(RBResolverStateFulfilled)];
         [resolver stub:@selector(result) andReturn:@"Hello"];

         [executer execute:resolver];

         [[actions shouldEventually] receive:@selector(succeeded) andReturn:^NSString *(id value){ return nil; } withArguments:@"Hello"];
      });

      it(@"call catch", ^{
         NSException *exception = [NSException nullMock];

         [resolver stub:@selector(state) andReturn:theValue(RBResolverStateRejected)];
         [resolver stub:@selector(result) andReturn:exception];

         [executer execute:resolver];

         [[actions shouldEventually] receive:@selector(catched) andReturn:^NSException *(NSException *e){ return nil; } withArguments:exception];
      });
   });

   describe(@"result when", ^{
      it(@"returning value from callback", ^{
         [resolver stub:@selector(state) andReturn:theValue(RBResolverStateFulfilled)];
         [actions stub:@selector(succeeded) andReturn:^{ return @"Good result"; } ];

         [executer execute:resolver];

         [[expectFutureValue(executer.result) shouldEventually] equal:@"Good result"];
      });

      it(@"Throw an exception", ^{
         NSException *exception = [NSException nullMock];

         [resolver stub:@selector(state) andReturn:theValue(RBResolverStateFulfilled)];
         [actions stub:@selector(succeeded) andReturn:^{ @throw exception; return nil; }];

         [executer execute:resolver];

         [[expectFutureValue(executer.result) shouldEventually] equal:exception];
      });
   });
});

SPEC_END