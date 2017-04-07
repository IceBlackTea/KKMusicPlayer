//
//  UIImageView+LBBlurredImage.m
//  LBBlurredImage
//
//  Created by Luca Bernardi on 11/11/12.
//  Copyright (c) 2012 Luca Bernardi. All rights reserved.
//

#import "UIImageView+BlurredImage.h"
#import "UIImage+ImageEffects.h"

CGFloat const kBlurredImageDefaultBlurRadius            = 20.0;
CGFloat const kBlurredImageDefaultSaturationDeltaFactor = 1.8;

@implementation UIImageView (LBBlurredImage)

#pragma mark - LBBlurredImage Additions

- (void)setImageToBlur:(UIImage *)image
       completionBlock:(BlurredImageCompletionBlock)completion
{
    [self setImageToBlur:image
              blurRadius:kBlurredImageDefaultBlurRadius
         completionBlock:completion];
}

- (void)setImageToBlur:(UIImage *)image
            blurRadius:(CGFloat)blurRadius
       completionBlock:(BlurredImageCompletionBlock) completion
{
    NSParameterAssert(image);
    NSParameterAssert(blurRadius >= 0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        UIImage *blurredImage = [image applyBlurWithRadius:blurRadius
                                                 tintColor:nil
                                     saturationDeltaFactor:kBlurredImageDefaultSaturationDeltaFactor
                                                 maskImage:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = blurredImage;
            if (completion) {
                completion();
            }
        });
    });
}

@end
