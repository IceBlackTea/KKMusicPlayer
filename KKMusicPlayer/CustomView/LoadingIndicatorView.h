//
//  LoadingIndicatorView.h
//
//  Created by finegr on 16/7/8.
//  Copyright © 2016年 finegr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoadingIndicatorView : UIView

- (void)startAnimateWithTimeOut:(NSTimeInterval)timeout;
- (void)dismiss;
- (void)resetViewWithOrientation:(NSInteger)toOrientation;

@end
