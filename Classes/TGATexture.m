//-------------------------------------------------------------------
//	TGATexture - OpenGL Texture Class
//-------------------------------------------------------------------

#import "TGATexture.h"

@implementation TGATexture

@synthesize name = _name;
@synthesize width = _width;
@synthesize height = _height;
@synthesize depth = _depth;
@synthesize internalFormat = _internalFormat;
@synthesize hasAlpha = _hasAlpha;

- (unsigned char*)getRGBA:(FILE *)f size:(int)size
{
    unsigned char *rgba;
    unsigned char temp;
    int bread;
    int i;
	
    rgba = (unsigned char*)malloc(size * 4); 
	
    if (rgba == NULL)
        return 0;
	
    bread = fread(rgba, sizeof(unsigned char), size * 4, f); 
	
    /* TGA is stored in BGRA, make it RGBA */
    if (bread != size * 4)
    {
        free(rgba);
        return 0;
    }
	
    for (i = 0; i < size * 4; i += 4 )
    {
        temp = rgba[i];
        rgba[i] = rgba[i + 2];
        rgba[i + 2] = temp;
    }
	
    _internalFormat = GL_RGBA;
	_hasAlpha = TRUE;
	
    return rgba;
}

- (unsigned char*)getRGB:(FILE *)f size:(int)size
{
    unsigned char *rgb;
    unsigned char temp;
    int bread;
    int i;
	
    rgb = (unsigned char*)malloc(size * 3); 
	
    if (rgb == NULL)
        return 0;
	
    bread = fread(rgb, sizeof(unsigned char), size * 3, f);
	
    if (bread != size * 3)
    {
        free(rgb);
        return 0;
    }
	
    /* TGA is stored in BGR, make it RGB */
    for (i = 0; i < size * 3; i += 3)
    {
        temp = rgb[i];
        rgb[i] = rgb[i + 2];
        rgb[i + 2] = temp;
    }
	
    _internalFormat = GL_RGB;
	_hasAlpha = FALSE;
	
    return rgb;
}

- (unsigned char*)getGrayscale:(FILE *)f size:(int)size
{
    unsigned char *grayData;
    int bread;
	
    grayData = (unsigned char*)malloc(size);
	
    if (grayData == NULL)
        return 0;
	
    bread = fread(grayData, sizeof(unsigned char), size, f);
	
    if (bread != size)
    {
        free(grayData);
        return 0;
    }
	
    //_internalFormat = GL_ALPHA;
	_internalFormat = GL_LUMINANCE;
	_hasAlpha = FALSE;
	
    return grayData;
}

- (unsigned char*)getData:(FILE *)f size:(int)size
{
	if (_depth == 32)
		return [self getRGBA:f size:size];
	else if (_depth == 24)
		return [self getRGB:f size:size];
	else if (_depth == 8)
		return [self getGrayscale:f size:size];
	return NULL;
}

- (BOOL)checkSize:(int)size
{
	return TRUE;
}

- (BOOL)loadTGATextureFromFile:(NSString *)fileName
{
    unsigned char type[4];
    unsigned char info[7];
    unsigned char *imageData = NULL;
    int size;
    FILE *f;
	
    if (!(f = fopen([fileName UTF8String], "r+bt")))
        return FALSE;
	
	// Read in image type
    fread(&type, sizeof(char), 3, f);
	
	// Seek past header
	fseek(f, 12, SEEK_SET);
	
	// Read in color info
    fread(&info, sizeof(char), 6, f);
	
    if (type[1] != 0 || (type[2] != 2 && type[2] != 3))
        return FALSE;
	
    _width = info[0] + info[1] * 256; 
    _height = info[2] + info[3] * 256;
    _depth = info[4]; 
	
    size = _width * _height; 
	
	// Dimension must be a power of two
    if (![self checkSize:_width] || ![self checkSize:_height])
        return FALSE;
	
	// Make sure type is supported
    if (_depth != 32 && _depth != 24 && _depth != 8)
        return FALSE;
	
	imageData = [self getData:f size:size];
	
	// No image data
    if (imageData == NULL)
        return FALSE;
	
    fclose(f);
	
    glBindTexture(GL_TEXTURE_2D, _name);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    /* glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST); */
    /* glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glTexImage2D(GL_TEXTURE_2D, 0, _internalFormat, _width, _height, 0, _internalFormat, GL_UNSIGNED_BYTE, imageData);
	
    // Release image data, it's been uploaded
    free(imageData);
	
    return TRUE;
}

- (BOOL)loadTGA:(NSString *)fileName
{
	glGenTextures(1, &_name);
	return [self loadTGATextureFromFile:fileName];
}

- (void)use
{
	glBindTexture(GL_TEXTURE_2D, _name);
}

- (id)initWithContentsOfFile:(NSString *)path
{
	if (self = [super init])
	{
		_name = 0;
		_width = 0;
		_height = 0;
		_depth = 0;
		_internalFormat = GL_RGB;
		_hasAlpha = FALSE;
		
		[self loadTGA:path];
		[self use];
	}
	return self;
}

- (id)initWithContentsOfURL:(NSURL *)url
{
	if (![url isFileURL])
	{
		[self release];
		return nil;
	}
	
	return [self initWithContentsOfFile:[url path]];
}

+ (id)tgaTextureWithContentsOfFile:(NSString *)path
{
	return [[[self alloc] initWithContentsOfFile:path] autorelease];
}

+ (id)tgaTextureWithContentsOfURL:(NSURL *)url
{
	if (![url isFileURL])
		return nil;
	
	return [TGATexture tgaTextureWithContentsOfFile:[url path]];
}

- (void)dealloc
{
	if (_name != 0)
		glDeleteTextures(1, &_name);
	
	[super dealloc];
}

@end

