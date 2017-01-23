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


#import <Foundation/Foundation.h>

/*! @def LE_UNAVAILABLE_USE_INITIALIZER(designatedInitializer)
 @brief Provides a template implementation for init-family methods which have been marked as
 NS_UNAVILABLE. Stops the compiler from giving a warning when it's the super class'
 designated initializer, and gives callers useful feedback telling them what the
 new designated initializer is.
 @remarks Takes a SEL as a parameter instead of a string so that we get compiler warnings if the
 designated intializer's signature changes.
 @param designatedInitializer A SEL referencing the designated initializer.
 */
#define LE_UNAVAILABLE_USE_INITIALIZER(designatedInitializer) { \
    NSString *reason = [NSString stringWithFormat:@"Called: %@\nDesignated Initializer:%@", \
                                                  NSStringFromSelector(_cmd), \
                                                  NSStringFromSelector(designatedInitializer)]; \
    @throw [NSException exceptionWithName:@"Attempt to call unavailable initializer." \
                                   reason:reason \
                                userInfo:nil]; \
}

NS_ASSUME_NONNULL_BEGIN
@class LEServiceConfiguration;

#ifndef LEService_h
#define LEService_h


/**
 * @brief
 * Main API for interacting with the Janrain Capture for iOS library
 *
 * If you wish to include third party authentication in your iPhone or iPad
 * applications, you can use the JRCapture class to achieve this.
 **/

@protocol LEServiceDelegate <NSObject>

- (void)leServiceSuccess:(NSDictionary *)result;
- (void)leServiceFailure:(NSDictionary *)error;

@end

@interface LEService : NSObject

@property(nonatomic) NSString *captureApplicationId;
@property(nonatomic) NSString *captureClientId;
@property(nonatomic) NSString *captureFlowName;
@property(nonatomic) NSString *captureFlowVersion;
@property(nonatomic) NSString *captureFlowLocale;
@property(nonatomic) NSURL *policyCheckerHost;
@property(nonatomic) NSString *policyCheckerStage;
@property(nonatomic) NSString *policyCheckerTenant;

@property (nonatomic, weak) id<LEServiceDelegate> delegate;


- (nullable instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initFromServiceConfiguration:(NSDictionary *)config
                                                error:(NSError **_Nullable)error
                                             delegate:(id<LEServiceDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (void)postToPolicyChecker:(NSDictionary *)subjectKey
                 withHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))handler;

- (void)checkLoginWithToken:(NSString *)accessToken
                      error:(NSError **_Nullable)checkError;

- (void)checkLoginWithUUID:(NSString *)uuid
                     error:(NSError **_Nullable)checkError;


@end



#endif /* LEService_h */
NS_ASSUME_NONNULL_END
