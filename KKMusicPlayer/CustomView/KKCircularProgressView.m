//
//  KKCircularProgressView.m
//
//  Created by finger on 15/7/24.
//  Copyright (c) 2015年 finger. All rights reserved.
//

#import "KKCircularProgressView.h"

@implementation KKCircularProgressView
{
    UIColor *_backColor;
    UIColor *_progressColor;
    CGFloat _lineWidth;
    
    float   _progress;
}
@dynamic progress;

- (id)initWithFrame:(CGRect)frame backColor:(UIColor *)backColor progressColor:(UIColor *)progressColor lineWidth:(CGFloat)lineWidth
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _progress = 0;
        _backColor = backColor;
        _progressColor = progressColor;
        _lineWidth = lineWidth;
        
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (void)setProgress:(float)progress
{
    _progress = progress;
    
    [self setNeedsDisplay];
}

- (float)progress
{
    return _progress;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
//    [super drawRect:rect];
    
    // Drawing code
    
    // draw back circle
    UIBezierPath *backPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetWidth(self.frame)/2.0, CGRectGetHeight(self.frame)/2.0) radius: ((CGRectGetWidth(self.frame) - _lineWidth )/2.0) startAngle:(CGFloat) - M_PI_2 endAngle:(CGFloat)(- M_PI_2  + 2*M_PI) clockwise:YES];
    
    [_backColor set];
    backPath.lineWidth = _lineWidth;
    backPath.lineJoinStyle = kCGLineJoinRound;
    backPath.lineCapStyle = kCGLineCapRound;
    [backPath stroke];
    
    if (self.progress >= 0)
    {
        // draw progress circle
        UIBezierPath *progressPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetWidth(self.frame)/2.0, CGRectGetHeight(self.frame)/2.0) radius: ((CGRectGetWidth(self.frame) - _lineWidth )/2.0) startAngle:(CGFloat) - M_PI_2 endAngle:(CGFloat)(- M_PI_2 + self.progress * 2 * M_PI) clockwise:YES];
        
        [_progressColor set];
        progressPath.lineWidth = _lineWidth;
        progressPath.lineJoinStyle = kCGLineJoinRound;
        progressPath.lineCapStyle = kCGLineCapRound;
        [progressPath stroke];
    }
}


@end
