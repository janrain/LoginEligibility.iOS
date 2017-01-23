# LoginEligibility.iOS
iOS Framework that works with the MIAA Policy Checker service

**Usage**

The example code below was derived from implementing the framework with the Janrain SimpleCaptureDemo application found here:
https://github.com/janrain/jump.ios/tree/master/Samples/SimpleCaptureDemo

Add the Framework to your Xcode workspace.

You should see the "LoginEligibility.framework" showing in your target's "Linked Frameworks and Libraries".

In your View Controller that will receive the access token from the Janrain Mobile Libraries, import the "LEService.h" header file:
`#import "LEService.h"`

(Optional) Create an NSDictionary to store the LoginEligibility Configuration:

`@property NSDictionary *leServiceConfig;`

In your View Controller implement the "LEServiceDelegate" protocol:

`@interface RootViewController () <UIAlertViewDelegate, LinkedProfilesDelegate, LEServiceDelegate>`

Synthesize the LoginEligibility Configuration:

	@implementation RootViewController

	@synthesize leServiceConfig;

Add in the LEServiceDelegate Methods (update the logic as needed):

	- (void)leServiceSuccess:(NSDictionary *)result
	{
	    DLog(@"LEService Success: %@", result);
	    NSString *outcome = [result objectForKey:@"outcome"];
	    if([outcome isEqualToString:@"Complies"]){
		    [self configureViewsWithDisableOverride:NO ];
		    [self configureUserLabelAndIcon];
		    if (self.captureRecordStatus == JRCaptureRecordNewlyCreated)
		    {
		        [RootViewController showProfileForm:self.navigationController];
		        self.captureRecordStatus = nil;
		    }
	    }else{
	        NSArray *obligations = [result objectForKey:@"obligations"];
	        NSArray *reasons = [result objectForKey:@"reasons"];
	        DLog(@"LEService Violations Detected!");
	        DLog(@"LEService Violation Obligations: %@",obligations);
	        DLog(@"LEService Violation Reasons: %@",reasons);
	        self.currentUserLabel.text = @"No current user";
	        self.currentUserProviderIcon.image = nil;
	        [self signOutCurrentUser];
	        [self configureViewsWithDisableOverride:YES];
	        [self setAllButtonsEnabled:YES];
	    }
	}

	- (void)leServiceFailure:(NSDictionary *)error
	{
	    DLog(@"LEService Error: %@", error);
	}

If you want to store and load the LoginEligibilty Configuration from a plist file then use a method similar to the following:

	- (void)loadLEConfigFromPlist
	{
	    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"assets/LoginEligibility-config" ofType:@"plist"];
	    self.leServiceConfig = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	}

Create the LoginEligibility-config.plist file in your resources/assets/ folder:

	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>policyCheckerTenant</key>
		<string>tccc_shared_tenant</string>
		<key>policyCheckerStage</key>
		<string>dev</string>
		<key>policyCheckerHost</key>
		<string>https://abcdefgh.execute-api.somewhere.amazonaws.com</string>
		<key>captureApplicationId</key>
		<string>somecaptureapplicationid</string>
		<key>captureClientId</key>
		<string>somecaptureloginclientid</string>
		<key>captureFlowName</key>
		<string>coke_policy_checker</string>
		<key>captureFlowLocale</key>
		<string>en-US</string>
		<key>captureFlowVersion</key>
		<string>somecaptureflowversion</string>
	</dict>
	</plist>

In your View Controller's `viewDidLoad` method you can populate the LoginEligibility Configuration:

	- (void)viewDidLoad
	{
	    ...
	    [self loadLEConfigFromPlist];
	}

Where ever it is in your code base that you receive the final Janrain oAuth Access Token after login or registration, update the code to hand off the token to the LoginEligibility service:

	- (void)captureSignInDidSucceedForUser:(JRCaptureUser *)newCaptureUser
	                                status:(JRCaptureRecordStatus)captureRecordStatus
	{
	    DLog(@"");
	    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	    appDelegate.captureUser = newCaptureUser;
	    [appDelegate.prefs setObject:[NSKeyedArchiver archivedDataWithRootObject:appDelegate.captureUser]
	                          forKey:cJRCaptureUser];
	    self.rvc.captureRecordStatus = &(captureRecordStatus);
	    if([self.rvc.leServiceConfig count] ==0){
	        [self.rvc loadLEConfigFromPlist];
	    }

	    NSString *accessToken = [JRCapture getAccessToken];
	    LEService *leService = [[LEService alloc] initFromServiceConfiguration:self.rvc.leServiceConfig
	                                                                     error:nil
	                                                                  delegate:self.rvc];
	    NSError *checkError;
	    [leService checkLoginWithToken:accessToken error:&checkError];
	}

