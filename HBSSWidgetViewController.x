#import "HBSSWidgetViewController.h"
#import "HBSSShareButton.h"
#import <auki/KJUARR.h>
#import <BiteSMS/BSQCQRLauncher.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <PhotoLibraryServices/PLManagedAlbum.h>
#import <PhotoLibraryServices/PLManagedAsset.h>
#import <PhotoLibraryServices/PLPhotoLibrary.h>
#import <Social/Social.h>
#import <SpringBoard/SpringBoard.h>
#import <TwitkaFly/LibTwitkaFly.h>
#import <UIKit/UIWindow+Private.h>
#import <UIKit/UIImage+Private.h>
#include <objc/runtime.h>

void HBSSLoadPrefs();

typedef NS_ENUM(NSUInteger, HBSSService) {
	HBSSServiceTwitter,
	HBSSServiceFacebook,
	HBSSServiceMessages,
};

BOOL showTwitter, showFacebook, showMessages;

@implementation HBSSWidgetViewController {
	UIWindow *_composeWindow;
	UIWindow *_oldKeyWindow;
	Class _twitkaFlyClass;
	Class _biteSMSClass;
	Class _aukiClass;
}

#pragma mark - Constants

- (CGSize)preferredViewSize {
	return CGSizeMake([super preferredViewSize].width, 44.f);
}

- (NSString *)serviceForButton:(UIView *)button {
	switch ((HBSSService)button.tag) {
		case HBSSServiceTwitter:
			return SLServiceTypeTwitter;
			break;

		case HBSSServiceFacebook:
			return SLServiceTypeFacebook;
			break;

		case HBSSServiceMessages:
			return nil;
			break;
	}
}

#pragma mark - UIViewController

- (void)loadView {
	[super loadView];

	HBSSLoadPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)HBSSLoadPrefs, CFSTR("ws.hbang.sevenshare/ReloadPrefs"), NULL, kNilOptions);

	NSBundle *bundle = [NSBundle bundleForClass:self.class];
	HBSSShareButton *twitterButton = nil, *facebookButton = nil, *messageButton = nil;
	NSUInteger buttons = 0;

	_composeWindow = [[UIWindow alloc] initWithFrame:[UIWindow keyWindow].frame];
	_composeWindow.windowLevel = UIWindowLevelNotificationCenter + 1.f;
	_composeWindow.rootViewController = [[[UINavigationController alloc] initWithRootViewController:[[[UIViewController alloc] init] autorelease]] autorelease];
	((UINavigationController *)_composeWindow.rootViewController).navigationBarHidden = YES;

	_twitkaFlyClass = objc_getClass("LibTwitkaFly");
	_biteSMSClass = objc_getClass("BSQCQRLauncher");
	_aukiClass = objc_getClass("KJUARR");

	if (showTwitter) {
		buttons++;

		twitterButton = [HBSSShareButton button];
		twitterButton.tag = HBSSServiceTwitter;
		[twitterButton setTitle:@"Tweet" forState:UIControlStateNormal];
		[twitterButton setImage:[UIImage imageNamed:@"twitter" inBundle:bundle] forState:UIControlStateNormal];
		[twitterButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[twitterButton addGestureRecognizer:[[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonLongPressed:)] autorelease]];
		[self.view addSubview:twitterButton];
	}

	if (showFacebook) {
		buttons++;

		facebookButton = [HBSSShareButton button];
		facebookButton.tag = HBSSServiceFacebook;
		[facebookButton setTitle:@"Post" forState:UIControlStateNormal];
		[facebookButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[facebookButton setImage:[UIImage imageNamed:@"facebook" inBundle:bundle] forState:UIControlStateNormal];
		[facebookButton addGestureRecognizer:[[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonLongPressed:)] autorelease]];
		[self.view addSubview:facebookButton];
	}

	if (showMessages) {
		buttons++;

		messageButton = [HBSSShareButton button];
		messageButton.tag = HBSSServiceMessages;
		[messageButton setTitle:@"Message" forState:UIControlStateNormal];
		[messageButton setImage:[UIImage imageNamed:@"message" inBundle:bundle] forState:UIControlStateNormal];
		[messageButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];

		if ([MFMessageComposeViewController canSendAttachments]) {
			[messageButton addGestureRecognizer:[[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonLongPressed:)] autorelease]];
		}

		[self.view addSubview:messageButton];
	}

	CGRect buttonFrame = CGRectMake(0, 0, self.view.frame.size.width / buttons, self.view.frame.size.height);

	if (twitterButton) {
		twitterButton.frame = buttonFrame;
	}

	if (facebookButton) {
		buttonFrame.origin.x += buttonFrame.size.width;
		facebookButton.frame = buttonFrame;
	}

	if (messageButton) {
		buttonFrame.origin.x += buttonFrame.size.width;
		messageButton.frame = buttonFrame;
	}
}

#pragma mark - Callbacks

- (void)buttonPressed:(UIButton *)button {
	UIViewController *viewController = nil;

	if (button.tag == HBSSServiceTwitter && _twitkaFlyClass) {
		[[_twitkaFlyClass sharedTwitkaFly] showSheetWithInitialText:@"" andInitialImage:nil];
		return;
	} else if (button.tag == HBSSServiceMessages) {
		if (_aukiClass) {
			[_aukiClass doUrThing:nil];
			return;
		} else if (_biteSMSClass) {
			[_biteSMSClass showQuickCompose:((SpringBoard *)[UIApplication sharedApplication]).isLocked];
			return;
		} else {
			viewController = [[[MFMessageComposeViewController alloc] init] autorelease];
			((MFMessageComposeViewController *)viewController).messageComposeDelegate = self;
		}
	} else {
		viewController = [SLComposeViewController composeViewControllerForServiceType:[self serviceForButton:button]];
		((SLComposeViewController *)viewController).completionHandler = ^(SLComposeViewControllerResult result) {
			[self _dismissWindow];
		};
	}

	[self presentViewController:viewController];
}

- (void)buttonLongPressed:(UILongPressGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
		return;
	}

	UIViewController *viewController = nil;
	UIImage *lastPhoto = self.lastPhoto;

	if (!lastPhoto) {
		return;
	}

	if (gestureRecognizer.view.tag == HBSSServiceTwitter && _twitkaFlyClass) {
		[[_twitkaFlyClass sharedTwitkaFly] showSheetWithInitialText:@"" andInitialImage:lastPhoto];
		return;
	} else if (gestureRecognizer.view.tag == HBSSServiceMessages) {
		if (_aukiClass && [_aukiClass respondsToSelector:@selector(doUrThing:withImages:)]) {
			[_aukiClass doUrThing:nil withImages:@[ lastPhoto ]];
			return;
		} else {
			viewController = [[[MFMessageComposeViewController alloc] init] autorelease];
			((MFMessageComposeViewController *)viewController).messageComposeDelegate = self;
			[(MFMessageComposeViewController *)viewController addAttachmentData:UIImageJPEGRepresentation(lastPhoto, 1.f) typeIdentifier:(NSString *)kUTTypeJPEG filename:@"image.jpg"];
		}
	} else {
		viewController = [SLComposeViewController composeViewControllerForServiceType:[self serviceForButton:gestureRecognizer.view]];
		((SLComposeViewController *)viewController).completionHandler = ^(SLComposeViewControllerResult result) {
			[self _dismissWindow];
		};
		[(SLComposeViewController *)viewController addImage:lastPhoto];
	}

	[self presentViewController:viewController];
}

#pragma mark - Presenting

- (void)presentViewController:(UIViewController *)viewController {
	_oldKeyWindow = [[UIWindow keyWindow] retain];

	[_composeWindow makeKeyAndVisible];
	[(UINavigationController *)_composeWindow.rootViewController presentViewController:viewController animated:YES completion:nil];
}

- (void)_dismissWindow {
	[(UINavigationController *)_composeWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
	_composeWindow.hidden = YES;
	[_oldKeyWindow makeKeyAndVisible];
	[_oldKeyWindow release];
}

#pragma mark - Last photo

- (UIImage *)lastPhoto {
	PLManagedAsset *lastPhoto = [PLPhotoLibrary sharedPhotoLibrary].allPhotosAlbum.assets.lastObject;
	return lastPhoto ? [lastPhoto newFullSizeImage] : nil;
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)viewController didFinishWithResult:(MessageComposeResult)result {
	[self _dismissWindow];
}

@end

#pragma mark - Preferences

static NSString *const kHBSSPreferencesPath = @"/var/mobile/Library/Preferences/ws.hbang.sevenshare.plist";

static NSString *const kHBSSPreferencesShowTwitterKey = @"ShowTwitter";
static NSString *const kHBSSPreferencesShowFacebookKey = @"ShowFacebook";
static NSString *const kHBSSPreferencesShowMessagesKey = @"ShowMessages";

void HBSSLoadPrefs() {
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kHBSSPreferencesPath];

	showTwitter = GET_BOOL(kHBSSPreferencesShowTwitterKey, [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]);
	showFacebook = GET_BOOL(kHBSSPreferencesShowFacebookKey, [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]);
	showMessages = GET_BOOL(kHBSSPreferencesShowMessagesKey, [MFMessageComposeViewController canSendText]);

	if (!prefs) {
		[@{
			kHBSSPreferencesShowTwitterKey: @(showTwitter),
			kHBSSPreferencesShowFacebookKey: @(showFacebook),
			kHBSSPreferencesShowMessagesKey: @(showMessages),
		} writeToFile:kHBSSPreferencesPath atomically:YES];
	}
}
