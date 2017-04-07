//
//  KKCircularProgressView.h
//
//  Created by finger on 15/7/24.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KKCircularProgressView : UIView
@property(nonatomic,assign)float progress;

- (id)initWithFrame:(CGRect)frame backColor:(UIColor *)backColor progressColor:(UIColor *)progressColor lineWidth:(CGFloat)lineWidth;

@end
