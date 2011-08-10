//
//  EarthRenderer.m
//  EarthSimulation
//
//  Modified by Donald Ness on 12/18/10.
//  Created by David Jacobs on 3/8/10.
//

#import "EarthRenderer.h"
#include <math.h>

@implementation EarthRenderer

@synthesize rotX;
@synthesize rotY;
@synthesize autoRotX;
@synthesize autoRotY;
@synthesize scale;

#define EARTH_LONGITUDE	60	// Longitude Resolution (x)
#define EARTH_LATITUDE	60	// Latitude Resolution (y)
#define EARTH_RADIUS	6378	// In kilometers
#define WORLD_SCALE		0.01f	// Scale of world
#define MIN_SCALE		0.5f	// Max zoom out
#define MAX_SCALE		1.9f	// Max zoom in;

typedef struct { GLfloat x; GLfloat y; GLfloat z; } ESVertex;
typedef struct { GLfloat u; GLfloat v; } ESTexCoord;

ESVertex vertices[EARTH_LONGITUDE + 1][EARTH_LATITUDE + 1];
ESTexCoord mapping[EARTH_LONGITUDE + 1][EARTH_LATITUDE + 1];

- (void)setScale:(GLfloat)s
{
	if (MIN_SCALE < s && s < MAX_SCALE)
	{
		scale = s;
	}
}

- (id) init
{
	if (self = [super init])
	{
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context])
		{
            [self release];
            return nil;
        }
		
		// Set view buffers
		glGenFramebuffersOES(1, &viewFramebuffer);
		glGenRenderbuffersOES(1, &viewRenderbuffer);
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);

		// Antialiasing options
		msaaSupported = YES;
		msaaSampleSize = 4;
		
		if (msaaSupported)
		{
			// Set antialiasing buffers
			glGenFramebuffersOES(1, &msaaFramebuffer);
			glGenFramebuffersOES(1, &msaaRenderbuffer);
			glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaFramebuffer);
			glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaRenderbuffer);
			glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, 4, GL_RGB5_A1_OES, backingWidth, backingHeight);
			glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, msaaRenderbuffer);
			glGenRenderbuffersOES(1, &msaaDepthbuffer);
			glBindRenderbufferOES(GL_RENDERBUFFER_OES, msaaDepthbuffer);
			glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, msaaSampleSize, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
			glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, msaaDepthbuffer);
		}
		
		// Initialize defaults
		rotX = 15;
		rotY = 260;
		autoRotX = -0.01f;
		autoRotY = -1.5f;
		scale = 1;
		
		// Load texture
		NSString *path = [[NSBundle mainBundle] pathForResource:@"Earth" ofType:@"tga"];
		texture = [[TGATexture alloc] initWithContentsOfFile:path];
		glBindTexture(GL_TEXTURE_2D, texture.name);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1.0f);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		// Generate sphere geometry
		for (int x = 0; x <= EARTH_LONGITUDE; ++x)
		{
			for (int y = 0; y <= EARTH_LATITUDE; ++y)
			{
				// Angles around y-axis
				GLfloat ax = (x * 360.f / EARTH_LONGITUDE) * M_PI / 180.f;
				GLfloat ay = (-90.f + (y * 180.f / EARTH_LATITUDE)) * M_PI / 180.f;
				
				vertices[x][y].x = fabsf(cosf(ay)) * EARTH_RADIUS * sinf(ax);
				vertices[x][y].y = EARTH_RADIUS * sinf(ay);
				vertices[x][y].z = fabsf(cosf(ay)) * EARTH_RADIUS * cosf(ax);
				
				mapping[x][y].u = (GLfloat)x / EARTH_LONGITUDE;
				mapping[x][y].v = (GLfloat)y / EARTH_LATITUDE;
			}
		}
	}
	
	return self;
}

- (void) reset
{
	rotX = 15;
	rotY = 260;
	autoRotX = -0.01f;
	autoRotY = -1.5f;
	scale = 1;
}

// Equivalent of gluPerspective
void setPerspective(GLfloat fov, GLfloat aspect, GLfloat znear, GLfloat zfar)
{
	GLfloat xmin, xmax, ymin, ymax;
	xmax = znear * tanf(fov * M_PI / 360.f);
	xmin = -xmax;
	ymin = xmin * aspect;
	ymax = xmax * aspect;
	glFrustumf(xmin, xmax, ymin, ymax, znear, zfar);
}

- (void) render
{
	// Set current context
    [EAGLContext setCurrentContext:context];    
	
	// Setup scene
	const GLfloat nearZ = 0.1f;
	const GLfloat farZ = 120.f;
	const GLfloat fov = 65.f;
	GLfloat width = (GLfloat)backingWidth;
	GLfloat height = (GLfloat)backingHeight;
	GLfloat aspect = height / width;
	glEnable(GL_DEPTH_TEST);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	setPerspective(fov, aspect, nearZ, farZ);
	glViewport(0, 0, width, height);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	// Build vertex array
	static ESVertex v[EARTH_LATITUDE * EARTH_LONGITUDE * 6];
	static ESTexCoord m[EARTH_LATITUDE * EARTH_LONGITUDE * 6];
	int i = 0;
	for (int y = 0; y < EARTH_LATITUDE; ++y)
	{
		for (int x = 0; x < EARTH_LONGITUDE; ++x)
		{
			int x0 = x + 0;
			int y0 = y + 0;
			int x1 = x + 1;
			int y1 = y + 1;
			
			v[i+0] = vertices[x1][y1];
			v[i+1] = vertices[x0][y1];
			v[i+2] = vertices[x1][y0];
			v[i+3] = vertices[x1][y0];
			v[i+4] = vertices[x0][y1];
			v[i+5] = vertices[x0][y0];
			
			m[i+0] = mapping[x1][y1];
			m[i+1] = mapping[x0][y1];
			m[i+2] = mapping[x1][y0];
			m[i+3] = mapping[x1][y0];
			m[i+4] = mapping[x0][y1];
			m[i+5] = mapping[x0][y0];
			
			i += 6;
		}
	}
	
	// Auto rotate
	rotX += autoRotX * scale * 0.1f;
	rotY += autoRotY * scale * 0.1f;
	
    glClearColor(0.f, 0.f, 0.f, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glEnable(GL_CULL_FACE);
	glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	// Apply transformations
	glTranslatef(0.f, 0.f, -125.f);
	glScalef(WORLD_SCALE, WORLD_SCALE, WORLD_SCALE);
	glScalef(scale, scale, scale);
	glRotatef(rotX, 1, 0, 0);
	glRotatef(rotY, 0, 1, 0);
	
	// Render array
    glVertexPointer(3, GL_FLOAT, 0, &v);
	glTexCoordPointer(2, GL_FLOAT, 0, &m);
    glDrawArrays(GL_TRIANGLES, 0, EARTH_LATITUDE * EARTH_LONGITUDE * 6);

	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_CULL_FACE);
	
	if (msaaSupported)
	{
		// Antialiasing
		glBindFramebufferOES(GL_READ_FRAMEBUFFER_APPLE, msaaFramebuffer);
		glBindFramebufferOES(GL_DRAW_FRAMEBUFFER_APPLE, viewFramebuffer);
		glResolveMultisampleFramebufferAPPLE();	
	}

	// Swap buffers and render
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer
{
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);

    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}

- (void) dealloc
{
	// Tear down GL
	if (viewFramebuffer)
	{
		glDeleteFramebuffersOES(1, &viewFramebuffer);
		viewFramebuffer = 0;
	}

	if (viewRenderbuffer)
	{
		glDeleteRenderbuffersOES(1, &viewRenderbuffer);
		viewRenderbuffer = 0;
	}
	
	if (msaaFramebuffer)
	{
		glDeleteFramebuffersOES(1, &msaaFramebuffer);
		msaaFramebuffer = 0;
	}
	
	if (msaaRenderbuffer)
	{
		glDeleteFramebuffersOES(1, &msaaRenderbuffer);
		msaaRenderbuffer = 0;
	}
	
	if (msaaDepthbuffer)
	{
		glDeleteRenderbuffersOES(1, &msaaDepthbuffer);
		msaaDepthbuffer = 0;
	}
	
	// Tear down context
	if ([EAGLContext currentContext] == context)
	{
        [EAGLContext setCurrentContext:nil];	
	}
	
	[context release];
	
	[super dealloc];
}

@end
