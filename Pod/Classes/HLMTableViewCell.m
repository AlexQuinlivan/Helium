//
//  HLMTableViewCell.m
//  Pods
//
//  Created by Alex Quinlivan on 11/05/15.
//
//

#import "HLMTableViewCell.h"
#import "HLMLayout.h"
#import "HLMLayoutInflator.h"

@interface HLMTableViewCell ()
@property (nonatomic, weak) UIView* hlm_contentView;
@end

@implementation HLMTableViewCell

-(instancetype) initWithStyle:(UITableViewCellStyle) style reuseIdentifier:(NSString *) reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UIView* hlm_contentView = [[HLMLayoutInflator alloc] initWithLayout:self.layoutResource].inflate;
        self.hlm_contentView = hlm_contentView;
        [self.contentView addSubview:hlm_contentView];
    }
    return self;
}

-(void) layoutSubviews {
#ifdef LAYOUT_PERF
    NSDate* layoutStarted = NSDate.date;
#endif
    UIView* subview = self.hlm_contentView;
    if (subview) {
        if (!subview.hlm_layoutManager) {
            @throw [NSException exceptionWithName:@"HLMLayoutException"
                                           reason:[NSString stringWithFormat:@"View `(%@)` found in layout pass without layout manager", NSStringFromClass(subview.class)]
                                         userInfo:nil];
        }
        CGRect frame = self.frame;
        CGFloat width = frame.size.width;
        CGFloat height = frame.size.height;
        uint32_t childLayoutHeight = subview.hlm_layoutHeight;
        HLMMeasureSpec rootWidthMeasureSpec = [HLMLayout measureSpecWithSize:width mode:HLMMeasureSpecExactly];
        HLMMeasureSpec rootHeightMeasureSpec;
        if (height > 0) {
            rootHeightMeasureSpec = [HLMLayout measureSpecWithSize:childLayoutHeight mode:HLMMeasureSpecExactly];
        } else {
            // is layout_height=match_parent dangerous?
            rootHeightMeasureSpec = [HLMLayout measureSpecWithSize:0 mode:HLMMeasureSpecUnspecified];
        }
        [subview.hlm_layoutManager measure:subview
                                 widthSpec:rootWidthMeasureSpec
                                heightSpec:rootHeightMeasureSpec];
        [subview.hlm_layoutManager layout:subview
                                     left:0
                                      top:0
                                    right:subview.hlm_measuredWidth
                                   bottom:subview.hlm_measuredHeight];
        self.contentView.bounds = subview.bounds;
    }
    self.bounds = self.contentView.bounds;
#ifdef LAYOUT_PERF
    NSLog(@"[VERBOSE]: Cell layout took %.1fms", [NSDate.date timeIntervalSinceDate:layoutStarted] * 1000.f);
#endif
}

@end
