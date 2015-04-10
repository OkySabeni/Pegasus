//
//  AnimatedLoadingBar.m
//  Smokescreen
//
//  Created by Huebner, Rob on 9/23/14.
//  Copyright (c) 2014-2015 Vimeo (https://vimeo.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "AnimatedLoadingBar.h"

static CGFloat AnimationPeriod = 1.0f;
static CGFloat StripeWidth = 14.0f;
static CGFloat StripeSpacing = 38.0f;

@interface AnimatedLoadingBar ()

@property (nonatomic, strong) CAReplicatorLayer *stripeLayer;
@property (nonatomic, strong) CABasicAnimation *stripeAnimation;

@end

@implementation AnimatedLoadingBar

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupLoadingBar];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupLoadingBar];
    }
    
    return self;
}

- (void)startAnimating
{
    _stripeAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    _stripeAnimation.duration = AnimationPeriod;
    _stripeAnimation.repeatCount = HUGE_VALF;
    _stripeAnimation.autoreverses = NO;
    _stripeAnimation.fromValue = @(-2.0f*StripeSpacing);
    _stripeAnimation.toValue = @(0.0f);
    
    [self.stripeLayer addAnimation:_stripeAnimation forKey:@"animatesPosition"];
    
    [self setHidden:NO];
}

- (void)stopAnimating
{
    if (_hidesWhenStopped)
    {
        [self setHidden:YES];
    }
    
    [self.stripeLayer removeAllAnimations];
}

#pragma mark - Private

- (void)setupLoadingBar
{
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.25f];
    
    [self setupStripes];
}

- (void)setupStripes
{
    CGFloat stripeSquareLength = self.frame.size.height;
    CGRect stripesFrame = CGRectInset(self.frame, -stripeSquareLength, 0.0);
    int numStripes = (int) ceilf( stripesFrame.size.width / stripeSquareLength );
    
    CAShapeLayer *oneStripeLayer = [CAShapeLayer layer];
    CGMutablePathRef stripe = CGPathCreateMutable();
    CGPathMoveToPoint(stripe, 0, 0.0, stripeSquareLength);
    CGPathAddLineToPoint(stripe, 0, stripeSquareLength, 0.0);
    
    oneStripeLayer.path = stripe;
    oneStripeLayer.strokeColor = [UIColor colorWithRed:255.0f/255.0f green:131.0f/255.0f blue:250.0f/255.0f alpha:0.25f].CGColor;
    oneStripeLayer.lineWidth = StripeWidth;
    oneStripeLayer.lineCap = kCALineCapSquare;
    
    oneStripeLayer.anchorPoint = CGPointMake(0.0, 0.0);
    oneStripeLayer.position = CGPointMake(0.0, 0.0);
    
    _stripeLayer = [CAReplicatorLayer layer];
    [_stripeLayer addSublayer:oneStripeLayer];
    _stripeLayer.instanceCount = numStripes;
    _stripeLayer.instanceTransform = CATransform3DMakeTranslation(StripeSpacing, 0.0, 0.0);
    
    [self.layer addSublayer:_stripeLayer];
}

@end
