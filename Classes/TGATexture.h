//-------------------------------------------------------------------
//	TGATexture - OpenGL Texture Class
//-------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface TGATexture : NSObject
{
	GLuint _name;
	GLenum _internalFormat;
	uint32_t _width;
	uint32_t _height;
	uint32_t _depth;
	BOOL _hasAlpha;
}

- (id)initWithContentsOfFile:(NSString *)path;
- (id)initWithContentsOfURL:(NSURL *)url;
+ (id)tgaTextureWithContentsOfFile:(NSString *)path;
+ (id)tgaTextureWithContentsOfURL:(NSURL *)url;

@property (readonly) GLuint name;
@property (readonly) GLenum internalFormat;
@property (readonly) uint32_t width;
@property (readonly) uint32_t height;
@property (readonly) uint32_t depth;
@property (readonly) BOOL hasAlpha;

@end
