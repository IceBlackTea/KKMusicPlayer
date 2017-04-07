//
//  UIImage+Scale.h
//
//  Created by finger on 15/4/9.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage(Scale)

- (UIImage *)scaleToSize:(CGSize)size;

- (UIImage *)getThumbnailsFromScaleSize:(CGSize)size;

- (UIImage *)getImageApplyingAlpha:(float)theAlpha;

- (UIImage *)fixOrientationFromOrientation:(UIImageOrientation )fromImageOrientation;

- (UIImage *)scaleWithFactor:(float)scaleFloat quality:(CGFloat)compressionQuality;

@end
