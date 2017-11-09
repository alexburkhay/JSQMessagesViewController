//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "JSQMessagesCellTextView.h"

@implementation JSQMessagesCellTextView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.textColor = [UIColor whiteColor];
    self.editable = NO;
    self.selectable = YES;
    self.userInteractionEnabled = YES;
    self.dataDetectorTypes = UIDataDetectorTypeNone;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.scrollEnabled = NO;
    self.backgroundColor = [UIColor clearColor];
    self.contentInset = UIEdgeInsetsZero;
    self.scrollIndicatorInsets = UIEdgeInsetsZero;
    self.contentOffset = CGPointZero;
    self.textContainerInset = UIEdgeInsetsZero;
    self.textContainer.lineFragmentPadding = self.customLineFragmentPadding > 0.f ? self.customLineFragmentPadding : 0;
    self.linkTextAttributes = @{ NSForegroundColorAttributeName : [UIColor whiteColor],
                                 NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    
    // remove redundant gesture recognizers - to disable text selection with ability to click links etc.
    NSArray *textViewGestureRecognizers = self.gestureRecognizers;
    NSMutableArray *mutableArrayOfGestureRecognizers = [[NSMutableArray alloc] init];
    for (UIGestureRecognizer *gestureRecognizer in textViewGestureRecognizers) {
        if (![gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]
                && ([(UITapGestureRecognizer *)gestureRecognizer numberOfTapsRequired] > 1 || [(UITapGestureRecognizer *)gestureRecognizer numberOfTouchesRequired] > 1)) {
//                NSLog(@"--- taps req : %f", [(UITapGestureRecognizer*)gestureRecognizer ]);
                continue;
            }
//            [mutableArrayOfGestureRecognizers addObject:gestureRecognizer];
        } else {
            UILongPressGestureRecognizer *longPressGestureRecognizer = (UILongPressGestureRecognizer *)gestureRecognizer;
            if (longPressGestureRecognizer.minimumPressDuration < 0.3 || longPressGestureRecognizer.minimumPressDuration > 0.6) {
                [mutableArrayOfGestureRecognizers addObject:gestureRecognizer];
            }
        }
    }
    self.gestureRecognizers = mutableArrayOfGestureRecognizers;
}

- (void)setCustomLineFragmentPadding:(CGFloat)customLineFragmentPadding {
    _customLineFragmentPadding = customLineFragmentPadding;
    if (customLineFragmentPadding >= 0) {
        self.textContainer.lineFragmentPadding = customLineFragmentPadding;
    }
}

- (void)setSelectedRange:(NSRange)selectedRange
{
    //  attempt to prevent selecting text
    [super setSelectedRange:NSMakeRange(NSNotFound, 0)];
}

- (NSRange)selectedRange
{
    //  attempt to prevent selecting text
    return NSMakeRange(NSNotFound, NSNotFound);
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    //  ignore double-tap to prevent copy/define/etc. menu from showing
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gestureRecognizer;
        if (tap.numberOfTapsRequired == 2) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    //  ignore double-tap to prevent copy/define/etc. menu from showing
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gestureRecognizer;
        if (tap.numberOfTapsRequired == 2) {
            return NO;
        }
    }
    
    return YES;
}

@end
