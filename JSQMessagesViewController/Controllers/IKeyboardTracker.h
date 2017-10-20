//
//  IKeyboardTracker.h
//  JSQMessages
//
//  Created by Alexander Burkhai on 10/20/17.
//  Copyright © 2017 Hexed Bits. All rights reserved.
//

#ifndef IKeyboardTracker_h
#define IKeyboardTracker_h


@protocol IKeyboardTracker <NSObject>

- (instancetype)initWithViewController:(UIViewController *)viewController inputContainer:(UIView *)inputContainer layoutBlock:(void (^)(CGFloat))layoutBlock notificationCenter:(NSNotificationCenter * _Nonnull)notificationCenter;

- (UIView *)trackingView;

- (void)startTracking;
- (void)stopTracking;
- (void)adjustTrackingViewSizeIfNeeded;

@end

#endif /* IKeyboardTracker_h */
