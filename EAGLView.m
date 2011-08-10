//
//  EAGLView.m
//  EarthSimulation
//
//  Modified by Donald Ness on 12/18/10.
//  Created by David Jacobs on 3/8/10.
//

#import "EAGLView.h"
#import "EarthRenderer.h"

@implementation EAGLView

@synthesize animating;
@dynamic animationFrameInterval;

// You must implement this method
+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id) initWithCoder:(NSCoder*)coder
{    
    if ((self = [super initWithCoder:coder]))
	{
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		renderer = [[EarthRenderer alloc] init];
		
		if (!renderer)
		{
			[self release];
			return nil;
		}
        
		animating = FALSE;
		displayLinkSupported = FALSE;
		animationFrameInterval = 1;
		displayLink = nil;
		animationTimer = nil;
		
		// A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
		// class is used as fallback when it isn't available.
		NSString *reqSysVer = @"3.1";
		NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
		if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
		{
			displayLinkSupported = TRUE;	
		}
    }
	
    return self;
}

- (void) drawView:(id)sender
{
    [renderer render];
}

- (void) layoutSubviews
{
	[renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:nil];
}

- (NSInteger) animationFrameInterval
{
	return animationFrameInterval;
}

- (void) setAnimationFrameInterval:(NSInteger)frameInterval
{
	if (frameInterval >= 1)
	{
		animationFrameInterval = frameInterval;
		
		if (animating)
		{
			[self stopAnimation];
			[self startAnimation];
		}
	}
}

- (void) startAnimation
{
	if (!animating)
	{
		if (displayLinkSupported)
		{
			displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
			[displayLink setFrameInterval:animationFrameInterval];
			[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		}
		else
		{
			animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(drawView:) userInfo:nil repeats:TRUE];	
		}
		
		animating = TRUE;
	}
}

- (void) stopAnimation
{
	if (animating)
	{
		if (displayLinkSupported)
		{
			[displayLink invalidate];
			displayLink = nil;
		}
		else
		{
			[animationTimer invalidate];
			animationTimer = nil;
		}
		
		animating = FALSE;
	}
}

- (float) distanceFromPoint:(CGPoint)pointA toPoint:(CGPoint)pointB
{
	float xD = fabs(pointA.x - pointB.x);
	float yD = fabs(pointA.y - pointB.y);
	
	return sqrt(xD*xD + yD*yD);
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touchA, *touchB;
	CGPoint pointA, pointB;
	
	if ([touches count] == 1)
	{
		touchA = [[touches allObjects] objectAtIndex:0];
		pointA = [touchA locationInView:self];
		pointB = [touchA previousLocationInView:self];
		
		float distanceY = pointA.x - pointB.x;
		float distanceX = pointA.y - pointB.y;
		
		GLfloat rotX = [renderer rotX];
		GLfloat rotY = [renderer rotY];
		[renderer setRotX:(rotX + 0.5 * distanceX)];
		[renderer setRotY:(rotY + 0.5 * distanceY)];
		[renderer setAutoRotX:(0.25 * distanceX)];
		[renderer setAutoRotY:(0.25 * distanceY)];
		
		[self drawView:nil];
	}
	else if ([touches count] == 2)
	{
		touchA = [[touches allObjects] objectAtIndex:0];
		touchB = [[touches allObjects] objectAtIndex:1];
		
		pointA = [touchA locationInView:self];
		pointB = [touchB locationInView:self];
		
		float currDistance = [self distanceFromPoint:pointA toPoint:pointB];
		
		pointA = [touchA previousLocationInView:self];
		pointB = [touchB previousLocationInView:self];
		
		float prevDistance = [self distanceFromPoint:pointA toPoint:pointB];
		
		GLfloat scale = [renderer scale];
		[renderer setScale:(scale + 0.005 * (currDistance - prevDistance))];
		
		[self drawView:nil];
	}
}

- (BOOL) canBecomeFirstResponder
{
	return YES;
}

- (void) motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.subtype == UIEventSubtypeMotionShake)
    {
        [renderer reset];
    }
	
    if ([super respondsToSelector:@selector(motionEnded:withEvent:)])
	{
        [super motionEnded:motion withEvent:event];
	}
}

- (void) dealloc
{
    [renderer release];
    [super dealloc];
}

@end
