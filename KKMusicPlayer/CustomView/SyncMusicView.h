#import <UIKit/UIKit.h>

@interface SyncMusicView : UIView
{
}

@property(nonatomic) UIImageView *bgView;
@property(nonatomic) NSString *strMsg;
@property(nonatomic) CGFloat percent;

- (void)setCircleViewPercent:(CGFloat)percent;
- (void)setCircleViewMsg:(NSString *)strMsg;

- (void)dismiss;
- (void)startAnimate;
- (void)resetViewWithOrientation:(NSInteger)toOrientation;

@end
