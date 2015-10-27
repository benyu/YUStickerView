//
//  YUStickerView.m
//  Babe
//
//  Created by Yu Jiang on 6/4/15.
//  Copyright (c) 2015 Benyu. All rights reserved.
//

#import "YUStickerView.h"

CG_INLINE CGPoint CGRectGetCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CG_INLINE CGRect CGRectScale(CGRect rect, CGFloat wScale, CGFloat hScale)
{
    return CGRectMake(rect.origin.x * wScale, rect.origin.y * hScale, rect.size.width * wScale, rect.size.height * hScale);
}

CG_INLINE CGFloat CGPointGetDistance(CGPoint point1, CGPoint point2)
{
    //Saving Variables.
    CGFloat fx = (point2.x - point1.x);
    CGFloat fy = (point2.y - point1.y);
    
    return sqrt((fx*fx + fy*fy));
}

CG_INLINE CGFloat CGAffineTransformGetAngle(CGAffineTransform t)
{
    return atan2(t.b, t.a);
}
/*
CG_INLINE CGSize CGAffineTransformGetScale(CGAffineTransform t){
    return CGSizeMake(sqrt(t.a * t.a + t.c * t.c), sqrt(t.b * t.b + t.d * t.d)) ;
}
 */

@interface YUStickerView (){
    CGPoint prevPoint;
    CGPoint touchLocation;
    
    CGRect initialBounds;
    CGFloat initialDistance;
    
    CGPoint beginningPoint;
    CGPoint beginningCenter;
    
    CGFloat deltaAngle;
    
    CGAffineTransform startTransform;
    CGRect beginBounds;
    
    CGSize inset;
}
@property(nonatomic, retain) CALayer *border;
@property(nonatomic, retain) UIImageView *imageView;
@property(nonatomic, retain) UIImageView *rotateView;
@property(nonatomic, retain) UIImageView *removeView;
@end

@implementation YUStickerView

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame: frame];
    
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        
        _editable = YES;
        
        _imageView = [[UIImageView alloc] initWithFrame: frame];

        _rotateView = [[UIImageView alloc] initWithImage:[UIImage imageNamed: @"editor.sticker.resize.png"]];
        _rotateView.userInteractionEnabled = YES;
        [_rotateView sizeToFit];
        
        _removeView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"editor.sticker.remove.png"]];
        _removeView.userInteractionEnabled = YES;
        [_removeView sizeToFit];
        
        inset.width = MAX(_rotateView.image.size.width, _removeView.image.size.width);
        inset.height = MAX(_rotateView.image.size.height, _removeView.image.size.height);

        
        [self addSubview: _imageView];
        [self addSubview: _rotateView];
        [self addSubview: _removeView];
        
        UIPanGestureRecognizer *moveGesture = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                                                      action: @selector(moveGesture:)];
        [self addGestureRecognizer: moveGesture];
        
        UITapGestureRecognizer *singleTapShowHide = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                            action: @selector(contentTapped:)];
        [self addGestureRecognizer:singleTapShowHide];
        
        UITapGestureRecognizer *closeTap = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                   action: @selector(tapToRemoveSelfFromSuperview:)];
        [_removeView addGestureRecognizer:closeTap];
        
        UIPanGestureRecognizer *panRotateGesture = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                                                           action: @selector(rotateViewPanGesture:)];
        [_rotateView addGestureRecognizer:panRotateGesture];
        
        [moveGesture requireGestureRecognizerToFail:closeTap];
    }
    
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    //smaller than screen's bounds
    CGSize size = self.bounds.size;
    
    CGFloat width = size.width - inset.width;
    CGFloat height = size.height - inset.height;
    
    _imageView.frame = CGRectMake(inset.width / 2, inset.height / 2, width, height);
    _rotateView.frame = CGRectMake(width, height, _rotateView.image.size.width, _rotateView.image.size.height);
}

- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];

    [shapeLayer setFillColor:[[UIColor clearColor] CGColor]];
    [shapeLayer setStrokeColor:[[UIColor whiteColor] CGColor]];
    [shapeLayer setLineWidth: 1.0f];
    [shapeLayer setLineJoin: kCALineJoinRound];
    [shapeLayer setLineDashPhase: 2];
//    [shapeLayer setLineDashPattern: [NSArray arrayWithObjects:[NSNumber numberWithInt:15], [NSNumber numberWithInt:5],nil]];
    
    // Setup the path
    CGFloat x = inset.width / 2, y = inset.height / 2;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, x, y);
    
    CGPathAddLineToPoint(path, NULL, rect.size.width - x, y);
    
    CGPathAddLineToPoint(path, NULL, rect.size.width - x, rect.size.height - y);
    
    CGPathAddLineToPoint(path, NULL, x, rect.size.height - y);
    
    CGPathAddLineToPoint(path, NULL, x, y);
    
    
    [shapeLayer setPath:path];
    CGPathRelease(path);
    
    CALayer *layer = [[self.layer sublayers] objectAtIndex: 0];
    if ([layer isMemberOfClass: [CAShapeLayer class]]) {
//        [[[self.layer sublayers] objectAtIndex: 0] removeFromSuperlayer];
        [layer removeFromSuperlayer];
    }
    [[self layer] insertSublayer: shapeLayer atIndex:0 ];
}

#pragma mark - Property Setting

- (void)setImage:(UIImage *)image{
    
    _imageView.image = image;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)hideEditingHandlers: (BOOL)hidden{
//    _border.borderWidth = hidden == YES ?  0 : 1;
    _removeView.hidden = hidden;
    _rotateView.hidden = hidden;
    
    CALayer *layer = [[self.layer sublayers] objectAtIndex: 0];
    if ([layer isMemberOfClass: [CAShapeLayer class]]) {
        layer.hidden = hidden;
    }
    
    _editable = !hidden;
    
//    [self setNeedsDisplay];
//    if([delegate respondsToSelector:@selector(labelViewDidHideEditingHandles:)]) {
//        [delegate labelViewDidHideEditingHandles:self];
//    }
}

-(void)tapToRemoveSelfFromSuperview:(UIPanGestureRecognizer *)recognizer{
//    if (NO == self.preventsDeleting) {
        UIView * close = (UIView *)[recognizer view];
        [close.superview removeFromSuperview];

//    }
    
//    if([_delegate respondsToSelector:@selector(stickerViewDidClose:)]) {
//        [_delegate stickerViewDidClose:self];
//    }
}

- (void)contentTapped:(UITapGestureRecognizer *)gesture{

    [self hideEditingHandlers: NO];
}


#pragma mark - Touch & Move
-(void)moveGesture:(UIPanGestureRecognizer *)recognizer{
//    if (!isShowingEditingHandles) {
//        [self showEditingHandles];
//    }
    touchLocation = [recognizer locationInView:self.superview];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        beginningPoint = touchLocation;
        beginningCenter = self.center;
        
        [self setCenter:CGPointMake(beginningCenter.x+(touchLocation.x-beginningPoint.x), beginningCenter.y+(touchLocation.y-beginningPoint.y))];
        
        beginBounds = self.bounds;
        
//        if([delegate respondsToSelector:@selector(labelViewDidBeginEditing:)]) {
//            [delegate labelViewDidBeginEditing:self];
//        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self setCenter:CGPointMake(beginningCenter.x+(touchLocation.x-beginningPoint.x), beginningCenter.y+(touchLocation.y-beginningPoint.y))];
        
//        if([delegate respondsToSelector:@selector(labelViewDidChangeEditing:)]) {
//            [delegate labelViewDidChangeEditing:self];
//        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self setCenter:CGPointMake(beginningCenter.x+(touchLocation.x-beginningPoint.x), beginningCenter.y+(touchLocation.y-beginningPoint.y))];
        
//        if([delegate respondsToSelector:@selector(labelViewDidEndEditing:)]) {
//            [delegate labelViewDidEndEditing:self];
//        }
    }
    
    prevPoint = touchLocation;
}

- (void)rotateViewPanGesture:(UIPanGestureRecognizer *)recognizer{
    touchLocation = [recognizer locationInView:self.superview];
    
    CGPoint center = CGRectGetCenter(self.frame);
    
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        deltaAngle = atan2(touchLocation.y-center.y, touchLocation.x-center.x)-CGAffineTransformGetAngle(self.transform);
        
        initialBounds = self.bounds;
        initialDistance = CGPointGetDistance(center, touchLocation);
        
//        if([delegate respondsToSelector:@selector(labelViewDidBeginEditing:)]) {
//            [delegate labelViewDidBeginEditing:self];
//        }
    } else if ([recognizer state] == UIGestureRecognizerStateChanged) {
        float ang = atan2(touchLocation.y-center.y, touchLocation.x-center.x);
        
        float angleDiff = deltaAngle - ang;

        [self setTransform:CGAffineTransformMakeRotation(-angleDiff)];
        [self setNeedsDisplay];
        
        //Finding scale between current touchPoint and previous touchPoint
        double scale = sqrtf(CGPointGetDistance(center, touchLocation)/initialDistance);
        
        CGRect scaleRect = CGRectScale(initialBounds, scale, scale);
        
//        if (scaleRect.size.width >= (1+globalInset*2 + 20) && scaleRect.size.height >= (1+globalInset*2 + 20)) {
//            if (fontSize < 100 || CGRectGetWidth(scaleRect) < CGRectGetWidth(self.bounds)) {
//                [textView adjustsFontSizeToFillRect:scaleRect];
                [self setBounds:scaleRect];
//            }
//        }
//        
//        if([delegate respondsToSelector:@selector(labelViewDidChangeEditing:)]) {
//            [delegate labelViewDidChangeEditing:self];
//        }
    } else if ([recognizer state] == UIGestureRecognizerStateEnded) {
//        if([delegate respondsToSelector:@selector(labelViewDidEndEditing:)]) {
//            [delegate labelViewDidEndEditing:self];
//        }
        
    }
}


@end
