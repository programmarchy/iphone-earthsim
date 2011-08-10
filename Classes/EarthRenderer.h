//
//  EarthRenderer.h
//  EarthSimulation
//
//  Modified by Donald Ness on 12/18/10.
//  Created by David Jacobs on 3/8/10.
//

#import "PVRTexture.h"
#import "TGATexture.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

@interface EarthRenderer : NSObject
{
@private
	EAGLContext *context;
	
	// The pixel dimensions of the CAEAGLLayer
	GLint backingWidth;
	GLint backingHeight;
	
	// User transformations
	GLfloat rotX;
	GLfloat rotY;
	GLfloat autoRotX;
	GLfloat autoRotY;
	GLfloat scale;
	
	// View buffers
	GLuint viewFramebuffer;
	GLuint viewRenderbuffer;
	
	// Antialiasing buffers
	BOOL msaaSupported;
	GLsizei msaaSampleSize;
	GLuint msaaFramebuffer;
	GLuint msaaRenderbuffer;
	GLuint msaaDepthbuffer;
	
	// Loaded textures
	TGATexture *texture;
}

@property (nonatomic) GLfloat rotX;
@property (nonatomic) GLfloat rotY;
@property (nonatomic) GLfloat autoRotX;
@property (nonatomic) GLfloat autoRotY;
@property (nonatomic) GLfloat scale;

- (void) render;
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer;
- (void) reset;

@end
