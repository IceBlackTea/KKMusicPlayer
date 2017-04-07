
#import "SyncMusicView.h"

@interface WXProgressView : UIView
{
    
}

@property(nonatomic) UIColor *circleColor;//圆环的颜色
@property(nonatomic) UIColor *inactiveColor;//圆环，未用部分的颜色
@property(nonatomic) UIColor *activeColor;//圆环，已用部分的颜色

@property(nonatomic) UIColor *fontColor;//字体颜色
@property(nonatomic) UIFont *font;//字体
@property(nonatomic) UILabel *msgLabel;
@property(nonatomic) NSString *msgText;

@property(nonatomic,assign) CGFloat lineWidth;

@property(nonatomic,assign) CGFloat percent;

@end

@implementation WXProgressView
{
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        self.circleColor = [UIColor lightTextColor];
        self.activeColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.5];
        self.inactiveColor = [UIColor lightTextColor];
        self.fontColor = [UIColor whiteColor];
        self.lineWidth = 1.0f;
        self.font = [UIFont systemFontOfSize:13.0];
        
        [self addSubContentView];
    }
    
    return self ;
}

- (void)addSubContentView
{
    _msgLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _msgLabel.textAlignment = NSTextAlignmentCenter;
    [_msgLabel setFont:_font];
    [_msgLabel setTextColor:_fontColor];
    [self addSubview:_msgLabel];
}

- (void)setFontColor:(UIColor *)fontColor
{
    _fontColor = fontColor;
    _msgLabel.textColor = fontColor;
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    _msgLabel.font = font ;
}

- (void)setMsgText:(NSString *)msgText
{
    _msgText = msgText ;
    _msgLabel.text = msgText ;
    
    CGSize size = [self sizeForString:msgText font:_msgLabel.font];
    if(size.width < 50){
        size.width = 50 ;
    }
    
    CGRect frame = self.frame ;
    frame.size.width = size.width;
    frame.size.height = size.width;
    self.frame = frame ;
    
    _msgLabel.frame = self.bounds ;
    
    [self setNeedsDisplay];
}

- (void)setPercent:(CGFloat)percent
{
    _percent = percent ;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat radius = CGRectGetWidth(rect) / 2.0f - self.lineWidth / 2.0f;
    
    CGContextSetLineWidth(context, self.lineWidth);
    
    CGContextBeginPath(context);
    CGFloat midX = CGRectGetMidX(rect);
    CGFloat midY = CGRectGetMidY(rect);
    CGContextAddArc(context, midX, midY, radius, 0, 2 * M_PI, 0);
    CGContextSetStrokeColorWithColor(context, [_circleColor CGColor]);
    CGContextStrokePath(context);
    
    CGFloat angle = _percent * M_PI * 2;
    CGContextBeginPath(context);
    CGContextAddArc(context, midX, midY, radius, angle - M_PI_2 , -M_PI_2 , 0);
    CGContextSetStrokeColorWithColor(context, [_inactiveColor CGColor]);
    CGContextStrokePath(context);
    
    CGContextBeginPath(context);
    CGContextAddArc(context, midX, midY, radius, -M_PI_2, angle - M_PI_2, 0);
    CGContextSetStrokeColorWithColor(context, [_activeColor CGColor]);
    CGContextStrokePath(context);
}

- (void)resetView
{
    _msgLabel.frame = self.bounds;
}

#pragma mark -- 计算字符串的Size

- (CGSize)sizeForString:(NSString*)text font:(UIFont*)font
{
    CGRect screen = [UIScreen mainScreen].bounds;
    CGFloat maxWidth = screen.size.width;
    CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);
    
    CGSize textSize = CGSizeZero;
    if ([text respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        
        NSStringDrawingOptions opts = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
        
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineBreakMode:NSLineBreakByCharWrapping];
        
        NSDictionary *attributes = @{ NSFontAttributeName : font, NSParagraphStyleAttributeName : style };
        
        CGRect rect = [text boundingRectWithSize:maxSize
                                         options:opts
                                      attributes:attributes
                                         context:nil];
        textSize = rect.size;
    }
    
    return textSize;
}

@end




///////////////////////////////////////////////////////////////



@interface SyncMusicView ()
{
    UIView *_contentView ;
    UILabel *_labelMsg ;
    
    WXProgressView *_circleView;
    
    NSInteger contentW ;
    NSInteger contentH ;
    NSInteger circleWH ;
    NSInteger lrPadding;
    NSInteger tbPadding;
}

@end

@implementation SyncMusicView

- (id)init
{
    self = [super init];
    if (self) {
        [self baseInit];
    }
    return self;
}

- (void)baseInit
{
    CGRect screen = [[UIScreen mainScreen]bounds];
    self.backgroundColor = [UIColor clearColor];
    self.frame = CGRectMake(0,0,screen.size.width,screen.size.height);
    
    lrPadding = 5 ;
    tbPadding = 5 ;
    
    contentW = 250 + 2 * lrPadding;
    contentH = 50 + 2 * tbPadding ;
    
    circleWH = 50 ;
    
    [self addBaseSubviews];
}

- (void)addBaseSubviews
{
    //模糊视图
    _bgView = [[UIImageView alloc]initWithFrame:self.frame];
    _bgView.backgroundColor = [UIColor clearColor];
    [self addSubview:_bgView];
    
    _contentView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, contentW, contentH)];
    _contentView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.7];
    _contentView.layer.cornerRadius = 5.0 ;
    _contentView.layer.masksToBounds = YES ;
    [self addSubview:_contentView];
    
    _circleView = [[WXProgressView alloc]initWithFrame:CGRectMake(0, 0, circleWH, circleWH)];
    [_circleView setBackgroundColor:[UIColor clearColor]];
    [_contentView addSubview:_circleView];
    
    _labelMsg = [[UILabel alloc]initWithFrame:CGRectMake(circleWH, 0, contentW - circleWH, contentH)];
    _labelMsg.backgroundColor = [UIColor clearColor];
    _labelMsg.font = [UIFont systemFontOfSize:15.0];
    _labelMsg.textColor = [UIColor whiteColor];
    _labelMsg.textAlignment = NSTextAlignmentCenter;
    _labelMsg.lineBreakMode = NSLineBreakByWordWrapping;
    _labelMsg.numberOfLines = 0;
    [_contentView addSubview:_labelMsg];
    
    [self adjustView];
}

- (void)dismiss
{
    [UIView animateWithDuration:0.2 animations:^{
        _contentView.maskView.alpha = 0 ;
    }];
    
    [UIView animateWithDuration:0.2 animations:^{
        _contentView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _contentView.alpha = 0;
            _contentView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4);
        } completion:^(BOOL finished2){
            [self removeFromSuperview];
        }];
    }];
}

- (void)startAnimate
{
    [[[[UIApplication sharedApplication]delegate] window] addSubview:self];
    
    ((UIView*)_contentView).maskView.alpha = 0;
    [UIView animateWithDuration:0.2 animations:^{
        _contentView.maskView.alpha = 1;
    }];
    
    _contentView.alpha = 0;
    _contentView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4);
    [UIView animateWithDuration:0.2 animations:^{
        _contentView.alpha = 1;
        _contentView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _contentView.alpha = 1;
            _contentView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
        } completion:^(BOOL finished2) {}];
    }];
}

- (void)setCircleViewPercent:(CGFloat)percent
{
    _circleView.percent = percent ;
}

- (void)setCircleViewMsg:(NSString *)strMsg
{
    _circleView.msgText = strMsg ;
    
    [self adjustView];
}

- (void)setStrMsg:(NSString *)strMsg
{
    _strMsg = strMsg ;
    
    _labelMsg.text = strMsg ;
    
    [self adjustView];
}

- (void)resetViewWithOrientation:(NSInteger)toOrientation
{
    CGRect screen = [[UIScreen mainScreen]bounds];
    if(toOrientation == UIInterfaceOrientationPortrait || toOrientation == UIInterfaceOrientationPortraitUpsideDown){
        if(screen.size.width > screen.size.height){
            CGFloat width = screen.size.width ;
            screen.size.width = screen.size.height ;
            screen.size.height = width ;
        }
    }else{
        if(screen.size.width < screen.size.height){
            CGFloat width = screen.size.width ;
            screen.size.width = screen.size.height ;
            screen.size.height = width ;
        }
    }
    self.frame = CGRectMake(0,0,screen.size.width,screen.size.height);
    
    _bgView.frame = self.bounds;
    
    [self adjustView];
}

- (void)adjustView
{
    CGSize textSize = [_labelMsg.text boundingRectWithSize:CGSizeMake(_labelMsg.frame.size.width, CGFLOAT_MAX)
                                                   options:NSStringDrawingUsesLineFragmentOrigin |NSStringDrawingUsesFontLeading
                                                attributes:[NSDictionary dictionaryWithObjectsAndKeys:_labelMsg.font,NSFontAttributeName, nil]
                                                   context:nil].size ;
    
    CGRect frame = _contentView.frame ;
    contentH = MAX(textSize.height + 2 * tbPadding ,frame.size.height);
    frame.size.height = contentH ;
    frame.size.width = contentW ;
    _contentView.frame = frame ;
    _contentView.center = self.center ;
    
    frame = _circleView.frame ;
    frame.origin.x = lrPadding ;
    frame.origin.y = (_contentView.frame.size.height - frame.size.height) / 2 ;
    _circleView.frame = frame ;
    
    frame = _labelMsg.frame ;
    frame.origin.x = _circleView.frame.origin.x + _circleView.frame.size.width ;
    frame.origin.y = tbPadding ;
    frame.size.height = contentH - 2 * tbPadding;
    frame.size.width = contentW - 2 * lrPadding - _circleView.frame.size.width ;
    _labelMsg.frame = frame ;
}

@end
