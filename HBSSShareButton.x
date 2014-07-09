#import "HBSSShareButton.h"
#import <SpringBoard/SBTodayBulletinCell.h>

@implementation HBSSShareButton

+ (instancetype)button {
	HBSSShareButton *button = [self buttonWithType:UIButtonTypeSystem];

	button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	button.tintColor = [%c(SBTodayBulletinCell) defaultFontColor];
	button.titleLabel.font = [%c(SBTodayBulletinCell) defaultFont];
	[button setTitleColor:[%c(SBTodayBulletinCell) defaultFontColor] forState:UIControlStateNormal];

	return button;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
	CGRect rect = [super imageRectForContentRect:contentRect];
	rect.origin.y -= 1.f;
	rect.origin.x -= 3.f;
	return rect;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
	CGRect rect = [super titleRectForContentRect:contentRect];
	rect.origin.x += 3.f;
	return rect;
}

@end
