/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright (c) 2017, Janrain, Inc.
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 * Neither the name of the Janrain, Inc. nor the names of its
 contributors may be used to endorse or promote products derived from this
 software without specific prior written permission.
 
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "LEError.h"
#import "LEService.h"

/*! @brief The callback signature for @c NSURLSession 's @c dataTaskWithRequest:completionHandler:
 method, which we use to fake the network responses.
 */
typedef void(^DataTaskWithRequestCompletionHandler)(NSData *_Nullable data,
NSURLResponse *_Nullable response,
NSError *_Nullable error);

/*! @brief The function signature for a @c dataTaskWithRequest:completionHandler: implementation. Used
 for implementing a faked version of @c NSURLSession 's @c dataTaskWithURL:completionHandler:
 */
typedef NSURLSessionDataTask *(^DataTaskWithRequestCompletionImplementation)
(id _self, NSURLRequest *request, DataTaskWithRequestCompletionHandler completionHandler);

/*! @brief A block to be called during teardown.
 */
typedef void(^TeardownTask)();


@class LEService;

@interface TestDelegate : NSObject <LEServiceDelegate>
@property NSDictionary *compliesDict;
@property NSDictionary *violatesDict;
@property NSString *errorData;
@property XCTestExpectation *asyncExpectation;
- (id)init;
@end

@interface LEServiceTests : XCTestCase
+ (LEService *) testLEService;
@end

@interface LEServiceTests ()

@property TestDelegate *testDelegate;
@property NSDictionary *testConfig;

@end


@implementation LEServiceTests{
    /*! @brief A list of tasks to perform during tearDown.
     */
    NSMutableArray<TeardownTask> *_teardownTasks;
}

static NSString *const kCompliesDocument = @"{\"request\": {\"subject\": {\"id\": \"a9629006-fe97-44ad-84de-663f60df1792\"},\"resource\": {\"clientId\": \"zwuuekttku9agjg3v8sp5eekk7mvhkq9\"}},\"outcome\": \"Complies\"}";

static NSString *const kViolatesDocument = @"{\"request\": {\"subject\": {\"id\": \"f9fc2109-043b-4e5f-bd0e-f9cbbbc5356d\"},\"resource\": {\"clientId\": \"zwuuekttku9agjg3v8sp5eekk7mvhkq9\"}},\"outcome\": \"Violates\",\"obligations\": [\"UserShouldProvideLongFamilyName\"],\"reasons\":[\"UserIsTooYoung\",\"DisplayNameAbsent\"]}";

/*! @brief Replaces the given method with a block for testing, undoing the change during tearDown.
 @param method The method to replace.
 @param block The new implementation of the method to be used.
 */
- (void)replaceMethod:(Method)method withBlock:(id)block {
    IMP originalImpl = method_getImplementation(method);
    IMP testImpl = imp_implementationWithBlock(block);
    // swizzles the method
    method_setImplementation(method, testImpl);
    // unswizzles the method during teardown
    [_teardownTasks addObject:^(){
        method_setImplementation(method, originalImpl);
    }];
}

/*! @brief Replaces the given instance method with a block for testing, reversing the change during
 tearDown.
 @param class The class whose method will be replaced.
 @param selector The selector of the class method that will be replaced.
 @param block The new implementation of the method to be used.
 */
- (void)replaceInstanceMethodForClass:(Class)class selector:(SEL)selector withBlock:(id)block {
    Method method = class_getInstanceMethod(class, selector);
    [self replaceMethod:method withBlock:block];
}


- (void)setUp {
    [super setUp];
    self.testConfig = @{@"captureApplicationId": @"1234567890",
                           @"captureFlowName": @"testFlowName",
                           @"captureFlowVersion": @"testFlowVersion",
                           @"captureFlowLocale": @"en-US",
                           @"policyCheckerStage": @"testStage",
                           @"policyCheckerTenant": @"testTenant",
                           @"policyCheckerHost": @"http://www.test.com"};
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _teardownTasks = [NSMutableArray array];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    for (TeardownTask task in _teardownTasks) {
        task();
    }
    _teardownTasks = nil;
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}


+ (LEService *)testLEService{
    NSDictionary *testConfig = @{@"captureApplicationId": @"1234567890",
                                @"captureClientId": @"1234567890",
                                @"captureFlowName": @"testFlowName",
                                @"captureFlowVersion": @"testFlowVersion",
                                @"captureFlowLocale": @"en-US",
                                @"policyCheckerStage": @"testStage",
                                @"policyCheckerTenant": @"testTenant",
                                @"policyCheckerHost": @"http://www.test.com"};
    
    TestDelegate *testDelegate = [[TestDelegate alloc] init];
    
    LEService *leService = [[LEService alloc] initFromServiceConfiguration:testConfig
                                                                     error:nil
                                                                  delegate:testDelegate];
    return leService;
    
}

- (void)testInitializer {
    LEService *leService = [[self class] testLEService];
    XCTAssertEqualObjects(leService.captureApplicationId,
                          @"1234567890");
    XCTAssertEqualObjects(leService.captureClientId,
                          @"1234567890");
    XCTAssertEqualObjects(leService.captureFlowName,
                          @"testFlowName");
    XCTAssertEqualObjects(leService.captureFlowVersion,
                          @"testFlowVersion");
    XCTAssertEqualObjects(leService.captureFlowLocale,
                          @"en-US");
    XCTAssertEqualObjects(leService.policyCheckerStage,
                          @"testStage");
    XCTAssertEqualObjects(leService.policyCheckerTenant,
                          @"testTenant");
    XCTAssertEqualObjects(leService.policyCheckerHost,
                          [NSURL URLWithString:@"http://www.test.com"]);
}

- (void)testMissingStringInitializer {
    NSDictionary *badConfig = @{@"captureApplicationId": @"1234567890",
                                 @"captureFlowName": @"testFlowName",
                                 @"captureFlowVersion": @"testFlowVersion",
                                 @"captureFlowLocale": @"en-US",
                                 @"policyCheckerStage": @"testStage",
                                 @"policyCheckerTenant": @"testTenant",
                                 @"policyCheckerHost": @"http://www.test.com"};
    
    TestDelegate *testDelegate = [TestDelegate alloc];
    NSError *testError;
    LEService *leService = [[LEService alloc] initFromServiceConfiguration:badConfig
                                                                     error:&testError
                                                                  delegate:testDelegate];
    NSLog(@"%@", [testError description]);
    XCTAssertEqual(testError.code, -2);
    XCTAssertEqualObjects([testError localizedDescription],
                          @"Missing field: captureClientId");
    XCTAssertNil(leService);

}

- (void)testBadUrlInitializer {
    NSDictionary *badConfig = @{@"captureApplicationId": @"1234567890",
                                 @"captureClientId": @"1234567890",
                                 @"captureFlowName": @"testFlowName",
                                 @"captureFlowVersion": @"testFlowVersion",
                                 @"captureFlowLocale": @"en-US",
                                 @"policyCheckerStage": @"testStage",
                                 @"policyCheckerTenant": @"testTenant",
                                 @"policyCheckerHost": @"notaurl"};
    
    TestDelegate *testDelegate = [TestDelegate alloc];
    NSError *testError;
    LEService *leService = [[LEService alloc] initFromServiceConfiguration:badConfig
                                                                     error:&testError
                                                                  delegate:testDelegate];
    NSLog(@"%@", [testError description]);
    XCTAssertEqual(testError.code, -3);
    XCTAssertEqualObjects([testError localizedDescription],
                          @"Invalid URL: notaurl");
    XCTAssertNil(leService);
    
}

- (void)testPolicyCheckerCompliesAccessToken {
    DataTaskWithRequestCompletionImplementation successfulResponse =
    ^NSURLSessionDataTask *(
                            id _self, NSURLRequest *request, DataTaskWithRequestCompletionHandler completionHandler) {
        NSError *error;
        NSData *compliesData = [kCompliesDocument dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:compliesData options:0 error:&error];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        NSURL *url = [NSURL URLWithString:@"http://www.test.com"];
        NSHTTPURLResponse *jsonResponse =
        [[NSHTTPURLResponse alloc] initWithURL:url
                                    statusCode:200
                                   HTTPVersion:@"1.1"
                                  headerFields:nil];
        completionHandler(jsonData, jsonResponse, nil);
        return nil;
    };
    
    [self replaceInstanceMethodForClass:[NSURLSession class]
                               selector:@selector(dataTaskWithRequest:completionHandler:)
                              withBlock:successfulResponse];
    
    
    NSError *error;
    NSData *compliesData = [kCompliesDocument dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *expectedDictionary =[NSJSONSerialization JSONObjectWithData:compliesData options:0 error:&error];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate should be called."];
    
    TestDelegate *testDelegate = [[TestDelegate alloc] init];
    testDelegate.asyncExpectation = expectation;
    
    LEService *leService = [[LEService alloc] initFromServiceConfiguration:self.testConfig
                                                                     error:nil
                                                                  delegate:testDelegate];
    
    NSString *accessToken = @"accesstoken";
    NSError *checkError;
    [leService checkLoginWithToken:accessToken
                             error:&checkError];
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
        if (error != nil) {
            XCTFail(@"Failure: checkLoginWithToken exceeded 2 seconds.");
        }
        XCTAssertEqualObjects(testDelegate.compliesDict, expectedDictionary);
        XCTAssertNil(testDelegate.violatesDict);
        XCTAssertNil(testDelegate.errorData);
        
    }];
}

- (void)testPolicyCheckerViolates {
    DataTaskWithRequestCompletionImplementation successfulResponse =
    ^NSURLSessionDataTask *(
                            id _self, NSURLRequest *request, DataTaskWithRequestCompletionHandler completionHandler) {
        NSError *error;
        NSData *violatesData = [kViolatesDocument dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:violatesData options:0 error:&error];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        NSURL *url = [NSURL URLWithString:@"http://www.test.com"];
        NSHTTPURLResponse *jsonResponse =
        [[NSHTTPURLResponse alloc] initWithURL:url
                                    statusCode:200
                                   HTTPVersion:@"1.1"
                                  headerFields:nil];
        completionHandler(jsonData, jsonResponse, nil);
        return nil;
    };
    
    [self replaceInstanceMethodForClass:[NSURLSession class]
                               selector:@selector(dataTaskWithRequest:completionHandler:)
                              withBlock:successfulResponse];
    
    
    NSError *error;
    NSData *violatesData = [kViolatesDocument dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *expectedDictionary =[NSJSONSerialization JSONObjectWithData:violatesData options:0 error:&error];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate should be called."];
    
    TestDelegate *testDelegate = [[TestDelegate alloc] init];
    testDelegate.asyncExpectation = expectation;
    
    LEService *leService = [[LEService alloc] initFromServiceConfiguration:self.testConfig
                                                                     error:nil
                                                                  delegate:testDelegate];
    
    NSString *accessToken = @"accesstoken";
    NSError *checkError;
    [leService checkLoginWithToken:accessToken
                             error:&checkError];
    
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
        if (error != nil) {
            XCTFail(@"Failure: checkLoginWithToken exceeded 2 seconds.");
        }
        XCTAssertEqualObjects(testDelegate.violatesDict, expectedDictionary);
        XCTAssertNil(testDelegate.compliesDict);
        XCTAssertNil(testDelegate.errorData);
        
    }];
}

- (void)testPolicyCheckerNSError {
    DataTaskWithRequestCompletionImplementation successfulResponse =
    ^NSURLSessionDataTask *(
                            id _self, NSURLRequest *request, DataTaskWithRequestCompletionHandler completionHandler) {
        NSURL *url = [NSURL URLWithString:@"http://www.test.com"];
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[NSLocalizedDescriptionKey] = @"404 - Not Found";
        NSError *error = [NSError errorWithDomain:@"www.test.com"
                                             code:404
                                        userInfo:userInfo];
        NSHTTPURLResponse *jsonResponse =
        [[NSHTTPURLResponse alloc] initWithURL:url
                                    statusCode:404
                                   HTTPVersion:@"1.1"
                                  headerFields:nil];
        completionHandler(nil, jsonResponse, error);
        return nil;
    };
    
    [self replaceInstanceMethodForClass:[NSURLSession class]
                               selector:@selector(dataTaskWithRequest:completionHandler:)
                              withBlock:successfulResponse];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate should be called."];
    
    TestDelegate *testDelegate = [[TestDelegate alloc] init];
    testDelegate.asyncExpectation = expectation;
    
    LEService *leService = [[LEService alloc] initFromServiceConfiguration:self.testConfig
                                                                     error:nil
                                                                  delegate:testDelegate];
    
    NSString *accessToken = @"accesstoken";
    NSError *checkError;
    [leService checkLoginWithToken:accessToken
                             error:&checkError];
    
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
        if (error != nil) {
            XCTFail(@"Failure: checkLoginWithToken exceeded 2 seconds.");
        }
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"404 - Not Found", @"errorCode",nil];
        XCTAssertEqualObjects(testDelegate.errorData, errorDict);
        XCTAssertNil(testDelegate.compliesDict);
        XCTAssertNil(testDelegate.violatesDict);
        
    }];
}

- (void)testPolicyCheckerResponseErrorCode {
    DataTaskWithRequestCompletionImplementation successfulResponse =
    ^NSURLSessionDataTask *(
                            id _self, NSURLRequest *request, DataTaskWithRequestCompletionHandler completionHandler) {
        NSError *error;
        NSData *errorData = [@"{\"Error\":\"404 - Not Found\"}" dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:errorData options:0 error:&error];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        NSURL *url = [NSURL URLWithString:@"http://www.test.com"];
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[NSLocalizedDescriptionKey] = @"404 - Not Found";
    
        NSHTTPURLResponse *jsonResponse =
        [[NSHTTPURLResponse alloc] initWithURL:url
                                    statusCode:404
                                   HTTPVersion:@"1.1"
                                  headerFields:nil];
        completionHandler(jsonData, jsonResponse, nil);
        return nil;
    };
    
    [self replaceInstanceMethodForClass:[NSURLSession class]
                               selector:@selector(dataTaskWithRequest:completionHandler:)
                              withBlock:successfulResponse];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate should be called."];
    
    TestDelegate *testDelegate = [[TestDelegate alloc] init];
    testDelegate.asyncExpectation = expectation;
    
    LEService *leService = [[LEService alloc] initFromServiceConfiguration:self.testConfig
                                                                     error:nil
                                                                  delegate:testDelegate];
    
    NSString *accessToken = @"accesstoken";
    NSError *checkError;
    [leService checkLoginWithToken:accessToken
                             error:&checkError];
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
        if (error != nil) {
            XCTFail(@"Failure: checkLoginWithToken exceeded 2 seconds.");
        }
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"HTTP Error (404)", @"errorCode",nil];
        XCTAssertEqualObjects(testDelegate.errorData, errorDict);
        XCTAssertNil(testDelegate.compliesDict);
        XCTAssertNil(testDelegate.violatesDict);
        
    }];
}

- (void)testPolicyCheckerCompliesUUID {
    DataTaskWithRequestCompletionImplementation successfulResponse =
    ^NSURLSessionDataTask *(
                            id _self, NSURLRequest *request, DataTaskWithRequestCompletionHandler completionHandler) {
        NSError *error;
        NSData *compliesData = [kCompliesDocument dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:compliesData options:0 error:&error];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        NSURL *url = [NSURL URLWithString:@"http://www.test.com"];
        NSHTTPURLResponse *jsonResponse =
        [[NSHTTPURLResponse alloc] initWithURL:url
                                    statusCode:200
                                   HTTPVersion:@"1.1"
                                  headerFields:nil];
        completionHandler(jsonData, jsonResponse, nil);
        return nil;
    };
    
    [self replaceInstanceMethodForClass:[NSURLSession class]
                               selector:@selector(dataTaskWithRequest:completionHandler:)
                              withBlock:successfulResponse];
    
    
    NSError *error;
    NSData *compliesData = [kCompliesDocument dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *expectedDictionary =[NSJSONSerialization JSONObjectWithData:compliesData options:0 error:&error];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate should be called."];
    
    TestDelegate *testDelegate = [[TestDelegate alloc] init];
    testDelegate.asyncExpectation = expectation;
    
    LEService *leService = [[LEService alloc] initFromServiceConfiguration:self.testConfig
                                                                     error:nil
                                                                  delegate:testDelegate];
    
    NSString *uuid = @"somelonguuid";
    NSError *checkError;
    [leService checkLoginWithUUID:uuid
                             error:&checkError];
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
        if (error != nil) {
            XCTFail(@"Failure: checkLoginWithUUID exceeded 2 seconds.");
        }
        XCTAssertEqualObjects(testDelegate.compliesDict, expectedDictionary);
        XCTAssertNil(testDelegate.violatesDict);
        XCTAssertNil(testDelegate.errorData);
        
    }];
}

- (void)testNullUUID {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate should be called."];
    
    TestDelegate *testDelegate = [[TestDelegate alloc] init];
    testDelegate.asyncExpectation = expectation;
    
    LEService *leService = [[LEService alloc] initFromServiceConfiguration:self.testConfig
                                                                     error:nil
                                                                  delegate:testDelegate];
    
    NSString *uuid = @"";
    NSError *checkError;
    [leService checkLoginWithUUID:uuid
                            error:&checkError];
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
        if (error != nil) {
            XCTFail(@"Failure: checkLoginWithUUID exceeded 2 seconds.");
        }
        XCTAssertNil(testDelegate.compliesDict);
        XCTAssertNil(testDelegate.violatesDict);
        XCTAssertEqualObjects(testDelegate.errorData, @"checkLoginWithUUID: UUID is empty or nil");
        
    }];
}

- (void)testNullAccessToken {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delegate should be called."];
    
    TestDelegate *testDelegate = [[TestDelegate alloc] init];
    testDelegate.asyncExpectation = expectation;
    
    LEService *leService = [[LEService alloc] initFromServiceConfiguration:self.testConfig
                                                                     error:nil
                                                                  delegate:testDelegate];
    
    NSString *accessToken = @"";
    NSError *checkError;
    [leService checkLoginWithToken:accessToken
                            error:&checkError];
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
        if (error != nil) {
            XCTFail(@"Failure: checkLoginWithToken exceeded 2 seconds.");
        }
        XCTAssertNil(testDelegate.compliesDict);
        XCTAssertNil(testDelegate.violatesDict);
        XCTAssertEqualObjects(testDelegate.errorData, @"checkLoginWithToken: accessToken is empty or nil");
    }];
}


@end

@implementation TestDelegate

- (id)init
{
    self = [super init];
    if (self)
    {
        self.compliesDict = nil;
        self.violatesDict = nil;
        self.errorData = nil;
    }
    return self;
}

- (void)leServiceSuccess:(NSDictionary *)result
{
    NSString *outcome = [result objectForKey:@"outcome"];
    if([outcome isEqualToString:@"Complies"]){
        self.compliesDict = result;
    }else{
        self.violatesDict = result;
    }
    [[self asyncExpectation] fulfill];
}

- (void)leServiceFailure:(NSString *)error
{
    self.errorData = error;
    [[self asyncExpectation] fulfill];
}

@end
