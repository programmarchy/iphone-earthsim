//
//  EAGLView.h
//  EarthSimulation
//
//  Modified by Donald Ness on 12/18/10.
//  Created by David Jacobs on 3/8/10.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "EarthRenderer.h"


@interface EAGLView : UIView
{    
@private
	EarthRenderer *renderer;
	
	BOOL animating;
	NSInteger animationFrameInterval;
    NSTimer *animationTimer;
	id displayLink;
	BOOL displayLinkSupported;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

- (void) startAnimation;
- (void) stopAnimation;
- (void) drawView:(id)sender;

@end
