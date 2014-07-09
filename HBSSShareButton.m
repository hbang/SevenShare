#import "HBSSShareButton.h"

@implementation HBSSShareButton

+ (instancetype)button {
	HBSSShareButton *button = [self buttonWithType:UIButtonTypeSystem];

	button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	button.tintColor = [UIColor whiteColor];
	button.titleLabel.font = [UIFont systemFontOfSize:17.f];
	[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

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
