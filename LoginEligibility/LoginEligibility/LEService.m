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

#import "LEService.h"
#import "LEError.h"


NS_ASSUME_NONNULL_BEGIN


@implementation LEService

@synthesize captureApplicationId;
@synthesize captureClientId;
@synthesize captureFlowName;
@synthesize captureFlowVersion;
@synthesize captureFlowLocale;
@synthesize policyCheckerHost;
@synthesize policyCheckerStage;
@synthesize policyCheckerTenant;


- (nullable instancetype)init LE_UNAVAILABLE_USE_INITIALIZER(@selector(initFromServiceConfiguration:error:delegate:));

- (nullable instancetype)initFromServiceConfiguration:(NSDictionary *)config
                                                error:(NSError **_Nullable)error
                                             delegate:(id<LEServiceDelegate>)delegate{
    
    if (![[self class] configHasRequiredFields:config error:error]) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.captureApplicationId = [config objectForKey:@"captureApplicationId"];
        self.captureClientId = [config objectForKey:@"captureClientId"];
        self.captureFlowName = [config objectForKey:@"captureFlowName"];
        self.captureFlowVersion = [config objectForKey:@"captureFlowVersion"];
        self.captureFlowLocale = [config objectForKey:@"captureFlowLocale"];
        self.policyCheckerHost = [NSURL URLWithString:[config objectForKey:@"policyCheckerHost"]];
        self.policyCheckerTenant = [config objectForKey:@"policyCheckerTenant"];
        self.policyCheckerStage = [config objectForKey:@"policyCheckerStage"];
        _delegate = delegate;
    }
    
    return self;
   
}

+ (BOOL)configHasRequiredFields:(NSDictionary *)config
                              error:(NSError **_Nullable)error {
    static NSString *const kMissingFieldErrorText = @"Missing field: %@";
    static NSString *const kFieldNullErrorText = @"Null or Empty field: %@";
    static NSString *const kInvalidURLFieldErrorText = @"Invalid URL: %@";
    
    // Check required String fields are valid.
    NSArray *requiredFields = @[
                                @"captureApplicationId",
                                @"captureClientId",
                                @"captureFlowName",
                                @"captureFlowVersion",
                                @"captureFlowLocale",
                                @"policyCheckerStage",
                                @"policyCheckerTenant"
                                ];
    
    for (NSString *field in requiredFields) {
        if (!config[field]) {
            if (error) {
                NSString *errorText = [NSString stringWithFormat:kMissingFieldErrorText, field];
                *error = [LEError errorWithCode:LEErrorCodeInvalidConfigurationDictionary
                                          description:errorText];
                return NO;
            }
            
        }else{
            NSObject *object = config[field];
            if (object == [NSNull null]) {
                NSString *errorText = [NSString stringWithFormat:kFieldNullErrorText, field];
                *error = [LEError errorWithCode:LEErrorCodeEmptyConfigurationKeyValue
                                    description:errorText];
                return NO;
            }
        }
    }
    
    // Check required URL fields are valid URLs.
    NSArray *requiredURLFields = @[
                                   @"policyCheckerHost"
                                   ];
    
    for (NSString *field in requiredURLFields) {
        NSURL *testUrl = [NSURL URLWithString:config[field]];
        if (!testUrl || !testUrl.scheme || !testUrl.host) {
            if (error) {
                NSString *errorText = [NSString stringWithFormat:kInvalidURLFieldErrorText, config[field]];
                *error = [LEError errorWithCode:LEErrorCodeInvalidPolicyCheckerHostUrl
                                    description:errorText];
                return NO;
            }
        }
    }
    
    return YES;
}

- (void)postToPolicyChecker:(NSDictionary *)subjectKey
                 withHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))handler{
    
    
    NSDictionary *resourceKey = [NSDictionary dictionaryWithObjectsAndKeys:
                                 self.captureClientId, @"clientId",nil];
    NSDictionary *dataToSend = [NSDictionary dictionaryWithObjectsAndKeys:
                                 subjectKey, @"subject",
                                 @"access", @"action",
                                 resourceKey, @"resource", nil];
    
    NSArray *pathStrings = @[self.policyCheckerStage, @"tenants", self.policyCheckerTenant, @"authz_request"];
    NSURL *fullUrl = [self.policyCheckerHost URLByAppendingPathComponent:[pathStrings componentsJoinedByString: @"/"]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fullUrl];
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataToSend options:0 error:&error];
    NSString *jsonString;
    if (! jsonData) {
        NSLog(@"Error building json for PolicyChecker Service: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSData *requestData = [NSData dataWithBytes:[jsonString UTF8String] length:[jsonString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
        
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody: requestData];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

        NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:handler];
        [postDataTask resume];
    }
    
}

- (void)checkLoginWithToken:(NSString *)accessToken
                      error:(NSError **_Nullable)checkError{
    if([accessToken length] > 0){
        NSDictionary *accessTokenKey = [NSDictionary dictionaryWithObjectsAndKeys:
                                        accessToken, @"accessToken",nil];
        [self checkLogin:accessTokenKey];
    }else{
        NSString *errorText = @"checkLoginWithToken: accessToken is empty or nil";
        *checkError = [LEError errorWithCode:LEErrorCodeNilAccessToken
                            description:errorText];
        [self.delegate leServiceFailure:errorText];
    }
}

- (void)checkLoginWithUUID:(NSString *)uuid
                     error:(NSError **_Nullable)checkError{
    if([uuid length] > 0){
        NSDictionary *uuidKey = [NSDictionary dictionaryWithObjectsAndKeys:
                                        uuid, @"id",nil];
        [self checkLogin:uuidKey];
    }else{
        NSString *errorText = @"checkLoginWithUUID: UUID is empty or nil";
        *checkError = [LEError errorWithCode:LEErrorCodeNilUUID
                            description:errorText];
        [self.delegate leServiceFailure:errorText];
    }
    
}

- (void)checkLogin:(NSDictionary *)subjectKey{
    [self postToPolicyChecker:subjectKey
                  withHandler:^(NSData *rawData, NSURLResponse *response, NSError *error) {
                      NSString *string = [[NSString alloc] initWithData:rawData
                                                               encoding:NSUTF8StringEncoding];
                      
                      NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                      NSInteger code = [httpResponse statusCode];
                      NSLog(@"LEService response %@ with code %ld and error %@.\n", response, code, error);
                      if(error){
                          NSLog(@"NSURL Error: %@", [error description]);
                          [self.delegate leServiceFailure:[error localizedDescription]];
                      } else if (!(code >= 200 && code < 300)) {
                          NSString *errorData = [NSString stringWithFormat:@"HTTP Error (%ld): %@", (long)code, string];
                          NSLog(@"%@", errorData);
                          [self.delegate leServiceFailure:errorData];
                      } else {
                          NSError* jsonError;
                          NSDictionary* result = [NSJSONSerialization JSONObjectWithData:rawData
                                                                               options:kNilOptions
                                                                                 error:&jsonError];
                          if(jsonError){
                              NSLog(@"JSON Conversion Error : %@", [error description]);
                          }else{
                              [self.delegate leServiceSuccess:result];
                          }
                          
                      }
                  }];
    
}


@end;

NS_ASSUME_NONNULL_END
