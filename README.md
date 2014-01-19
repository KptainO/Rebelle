Rebelle
=======

Rebelle is an Objective-C implementation of Promises/A+ with a rebel syntax for an Objective-c project: the classical call syntax used in C, C++ and other languages and which allow you to chain your calls while still having your code readable.

You can follow project changes [here](CHANGELOG.md) and/or coming features [here](ROADMAP.md)

Any contribution is welcomed!

## What is a Rebelle promise
> A promise represents the eventual result of an asynchronous operation. The primary way of interacting with a promise is through its `then` method, which registers callbacks to receive either a promise's eventual value or the reason why the promise cannot be fulfilled
([promises documentation](https://github.com/promises-aplus/promises-spec))

That is, a promise allows you to execute actions (blocks) attached to it asynchronously.

## How to use it

Rebelle comes with a sample project. You can check it to see how things work. Or you can read below explanations.

### Basic usage
Creating a promise is quite simple:      
      
```Objective-C
RBPromise *promise = [RBPromise new];
      
promise.then(^id(NSString *result) {
  // execute any code when succeeded
  NSLog(@"success with result %@", result);
        
  return result;
        
}, ^id(NSException *exception) {
  // handle any exception
  NSLog(@"failed with exception %@", result);

  return exception;
});
    
[promise.resolve:@"hello world"]; // Rebelle will automatically call your success or exception callbacks
```

Now that you know how works a RBPromise, you can actually use it inside your code and return it so that any asynchronous code got executed once resolved.

(This is quick code to show how and when to use promises, but obviously this is not "clean" code)

```Objective-C
@implementation WebService
      
- (RBPromise *)getUser(int id) {
  self.promise = [RBPromise new];
        
  NSURLRequest aRequest = // request to server;
        
  // Call the server and get data about user
  // If you use classes that use delegates instead of callbacks, then you'll need
  // to save your promise inside a class attribute, otherwise just call it inside your blocks
        
  NSURLConnection *connection = [NSURLConnection connectionWithRequest:aRequest delegate:self];
        
  // this promise result (when succeeded) should be a User object
  return self.promise; // Return your promise so you can add chain blocks on it !
}
      
- (RBPromise *)getTweets:(User *)user {
  // Same idea than in getUser
  // This promise result is an NSArray of Tweet objects
}
      
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  [self.promise resolve: // result from the response];
}
      
@end
      
@implementation  MyApp

- (RBPromise *)sample {
  WebService *ws = [WebService new];
      
  // you 
  RBPromise *promise = [ws getUser];
        
  promise.then(^id(User *user) { user.lastLoggedIn = new Date(); return user; }, nil)
         .then(^id(User *user) { return [ws getTweets:user]; }, nil);
         .then(^id(NSArray *tweets) { // This code is executed only when tweets have been downloaded }, nil);
      
  return promise; // You can either return once again your promise so that any upper code chain on it too...
  // Everyhing will be resolved in the order when previous code has been executed !
}
      
@end
```

So what does this code ?

1. We're calling an asynchronous webservice `getUser`
2. Once user data is collected, we're setting some date on the user
3. Then we're calling another asynchronous webservice `getTweets`
4. Once tweets are collected, we're executing another block
5. And so go on...

> For more information about ```then``` and the chain syntax used by Rebelle, check the wiki [Promise chaining](../../wiki/Promise-chaining) page

### What about NSError ?!      

As shown before, the failure block take only NSException objects as argument (`^id(NSException exception)`). As NSError are also often used in Objective-C Rebelle also consider NSError objects as a failure and pass them to the failure block by wrapping them inside an RBErrorException class instance.

## Install

To install Rebelle the easiest (and preferred way) is through CocoaPods:


1. Add the project inside your Podfile

        pod Rebelle, '~> 1.0.x'
    
2. Update your installation
        
        pod install


## Under the hood

### Chainable syntax secret
To be able to have a chainable syntax Rebelle is massively using blocks as properties on RBPromise object instances. So when you're calling `then(SuccessBlock, FailureBlock)` you're in fact calling a NSBlock by passing it 2 arguments.

### Promises
For more information on Promises/A+, check the [documentation](https://github.com/promises-aplus/promises-spec) repository

![Promises/A+ logo](http://promisesaplus.com/assets/logo-small.png "Promises/A+ 1.0 compliant")
