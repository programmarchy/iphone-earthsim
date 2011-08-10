//
//  EarthAppDelegate.m
//  EarthSimulation
//
//  Modified by Donald Ness on 12/18/10.
//  Created by David Jacobs on 3/8/10.
//

#import "EarthAppDelegate.h"
#import "EAGLView.h"

@implementation EarthAppDelegate

@synthesize window;
@synthesize glView;

- (void) applicationDidFinishLaunching:(UIApplication *)application
{
	[application setStatusBarHidden:YES];
	[glView startAnimation];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[glView resignFirstResponder];
    [glView stopAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[glView becomeFirstResponder];
    [glView startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [glView stopAnimation];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Handle any background procedures not related to animation here.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Handle any foreground procedures not related to animation here.
}

- (void)dealloc
{
    [window release];
	[glView release];
    
    [super dealloc];
}

@end
