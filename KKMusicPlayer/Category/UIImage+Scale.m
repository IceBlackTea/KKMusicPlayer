//
//  UIImage+Scale.m
//
//  Created by finger on 15/4/9.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "UIImage+Scale.h"

@implementation UIImage(Scale)

- (UIImage *)scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaleImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaleImage;
}

#pragma warning  ----- 需要手动释放内存

- (UIImage *)getThumbnailsFromScaleSize:(CGSize)size
{
    CGFloat selfHeight = self.size.height;
    CGFloat selfWidth = self.size.width;
    
    float heightRadio = size.height*1.0 / selfHeight;
    float widthRadio = size.width*1.0 / selfWidth;
    
    float radio = 1;
    
    if (heightRadio > 1 && widthRadio > 1)
    {
        radio = heightRadio > widthRadio ? widthRadio : heightRadio ;
    }
    else
    {
        radio = heightRadio < widthRadio ? widthRadio : heightRadio ;
    }
    
    CGFloat scaleWidth = radio * selfWidth;
    CGFloat scaleHeight = radio * selfHeight;
    
    UIImage *scaleImage = [self scaleToSize:CGSizeMake(scaleWidth, scaleHeight)];
    
    CGRect trimRect = CGRectMake((scaleWidth - size.width)/2.0 , (scaleHeight - size.height)/2.0, size.width, size.height);
    
    CGImageRef resultImageRef = CGImageCreateWithImageInRect([scaleImage CGImage], trimRect);
    
    UIImage *newImage = [[UIImage alloc] initWithCGImage:resultImageRef];
    
    CGImageRelease(resultImageRef);
    
    return newImage;
    
}

- (UIImage *)getImageApplyingAlpha:(float)theAlpha
{
    UIGraphicsBeginImageContext(self.size);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height) blendMode:kCGBlendModeNormal alpha:theAlpha];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)fixOrientationFromOrientation:(UIImageOrientation)fromImageOrientation
{
    UIImage *new = [UIImage imageWithCGImage:self.CGImage scale:1 orientation:fromImageOrientation];
    return new;
    
    UIImageOrientation imageOrientation = fromImageOrientation;
    if (imageOrientation == UIImageOrientationUp)
    {
        return self;
    }
    
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, self.size.height, self.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, self.size.height, self.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            rotate = M_PI;
            rect = CGRectMake(0, 0, self.size.width, self.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, self.size.width, self.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), self.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    return newPic;
}

- (UIImage *)scaleWithFactor:(float)scaleFloat quality:(CGFloat)compressionQuality
{
    CGSize size = CGSizeMake(self.size.width * scaleFloat, self.size.height * scaleFloat);
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    transform = CGAffineTransformScale(transform, scaleFloat, scaleFloat);
    CGContextConcatCTM(context, transform);
    
    [self drawAtPoint:CGPointMake(0.0f, 0.0f)];
    UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imagedata = UIImageJPEGRepresentation(newimg,compressionQuality);
    
    return [UIImage imageWithData:imagedata] ;
}

@end
