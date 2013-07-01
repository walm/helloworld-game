//
//  SXParticleEmitter.m
//  Sparrow Particle System Extension
//
//  Created by Daniel Sperl on 02.06.11.
//  Copyright 2011 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SXParticleSystem.h"

#import <math.h>

// --- structs -------------------------------------------------------------------------------------

typedef struct
{
    SXColor4f color, colorDelta;
    float x, y;
    float startX, startY;
    float velocityX, velocityY;
    float radialAcceleration;
    float tangentialAcceleration;
    float radius, radiusDelta;
    float rotation, rotationDelta;
    float size, sizeDelta;
    float timeToLive;
} SXParticle;

// --- macros --------------------------------------------------------------------------------------

// square a number
#define SQ(x) ((x)*(x))

// returns an RGBA color encoded in an UINT
#define SX_RGBA(r, g, b, a)    (((int)(a) << 24) | ((int)(r) << 16) | ((int)(g) << 8) | (int)(b))

// returns a random number between 0 and 1
#define RANDOM_FLOAT()    ((float) arc4random() / UINT_MAX)

// returns a random value between (base - variance) and (base + variance)
#define RANDOM_VARIANCE(base, variance)    ((base) + (variance) * (RANDOM_FLOAT() * 2.0f - 1.0f))

#define RANDOM_COLOR_VARIANCE(base, variance)                                          \
(SXColor4f){ .red   = SP_CLAMP(RANDOM_VARIANCE(base.red,   variance.red),   0.0f, 1.0f),  \
             .green = SP_CLAMP(RANDOM_VARIANCE(base.green, variance.green), 0.0f, 1.0f),  \
             .blue  = SP_CLAMP(RANDOM_VARIANCE(base.blue,  variance.blue),  0.0f, 1.0f),  \
             .alpha = SP_CLAMP(RANDOM_VARIANCE(base.alpha, variance.alpha), 0.0f, 1.0f) }

// --- class implementation ------------------------------------------------------------------------

@implementation SXParticleSystem
{
    SPImage *_particleImage;
    SPTexture *_texture;
    SPQuadBatch *_quadBatch;
    SXParticle *_particles;
    
    NSString *_path;
    double _burstTime;
    double _frameTime;
    int _numParticles;
                                                    // .pex element name
    // emitter configuration
    SXParticleEmitterType _emitterType;             // emitterType
    float _emitterX;                                // sourcePosition x (ignored)
    float _emitterY;                                // sourcePosition y (ignored)
    float _emitterXVariance;                        // sourcePositionVariance x
    float _emitterYVariance;                        // sourcePositionVariance y
    
    // particle configuration
    int _maxNumParticles;                           // maxParticles
    float _lifespan;                                // particleLifeSpan
    float _lifespanVariance;                        // particleLifeSpanVariance
    float _startSize;                               // startParticleSize
    float _startSizeVariance;                       // startParticleSizeVariance
    float _endSize;                                 // finishParticleSize
    float _endSizeVariance;                         // finishParticleSize
    float _emitAngle;                               // angle
    float _emitAngleVariance;                       // angleVariance
    // [rotation not supported!]
    
    // gravity configuration
    float _speed;                                   // speed
    float _speedVariance;                           // speedVariance
    float _gravityX;                                // gravity x
    float _gravityY;                                // gravity y
    float _radialAcceleration;                      // radialAcceleration
    float _radialAccelerationVariance;              // radialAccelerationVariance
    float _tangentialAcceleration;                  // tangentialAcceleration
    float _tangentialAccelerationVariance;          // tangentialAccelerationVariance
    
    // radial configuration
    float _maxRadius;                               // maxRadius
    float _maxRadiusVariance;                       // maxRadiusVariance
    float _minRadius;                               // minRadius
    float _rotatePerSecond;                         // rotatePerSecond
    float _rotatePerSecondVariance;                 // rotatePerSecondVariance
    
    // color configuration
    SXColor4f _startColor;                          // startColor
    SXColor4f _startColorVariance;                  // startColorVariance
    SXColor4f _endColor;                            // finishColor
    SXColor4f _endColorVariance;                    // finishColorVariance
    
    // blend function
    uint _blendFuncSource;                          // blendFuncSource
    uint _blendFuncDestination;                     // blendFuncDestination
}

@synthesize numParticles = _numParticles;
@synthesize texture = _texture;
@synthesize startColor = _startColor;
@synthesize startColorVariance = _startColorVariance;
@synthesize endColor = _endColor;
@synthesize endColorVariance = _endColorVariance;
@synthesize emitterType = _emitterType;
@synthesize emitterX = _emitterX;
@synthesize emitterY = _emitterY;
@synthesize emitterXVariance = _emitterXVariance;
@synthesize emitterYVariance = _emitterYVariance;
@synthesize maxNumParticles = _maxNumParticles;
@synthesize lifespan = _lifespan;
@synthesize lifespanVariance = _lifespanVariance;
@synthesize startSize = _startSize;
@synthesize startSizeVariance = _startSizeVariance;
@synthesize endSize = _endSize;
@synthesize endSizeVariance = _endSizeVariance;
@synthesize emitAngle = _emitAngle;
@synthesize emitAngleVariance = _emitAngleVariance;
@synthesize speed = _speed;
@synthesize speedVariance = _speedVariance;
@synthesize gravityX = _gravityX;
@synthesize gravityY = _gravityY;
@synthesize radialAcceleration = _radialAcceleration;
@synthesize radialAccelerationVariance = _radialAccelerationVariance;
@synthesize tangentialAcceleration = _tangentialAcceleration;
@synthesize tangentialAccelerationVariance = _tangentialAccelerationVariance;
@synthesize maxRadius = _maxRadius;
@synthesize maxRadiusVariance = _maxRadiusVariance;
@synthesize minRadius = _minRadius;
@synthesize rotatePerSecond = _rotatePerSecond;
@synthesize rotatePerSecondVariance = _rotatePerSecondVariance;
@synthesize blendFuncSource = _blendFuncSource;
@synthesize blendFuncDestination = _blendFuncDestination;

- (id)initWithTexture:(SPTexture *)texture
{
    if ((self = [super init]))
    {
        _texture = texture;
        _quadBatch = [[SPQuadBatch alloc] init];
        
        // choose some useful defaults, just in case no config file is used
        _maxNumParticles = 32;
        _emitterType = SXParticleEmitterTypeGravity;
        _startColor = (SXColor4f){ 1.0f, 1.0f, 1.0f, 1.0f };
        _endColor   = (SXColor4f){ 0.0f, 0.0f, 0.0f, 0.0f };
        _lifespan = 1.0f;
        _startSize = texture ? texture.width : 32;
        _emitAngleVariance = PI / 8.0f;
        _speed = 256;
        _speedVariance = 64;
        _blendFuncSource = GL_ONE;
        _blendFuncDestination = GL_ONE_MINUS_SRC_ALPHA;
        _particles = malloc(sizeof(SXParticle) * _maxNumParticles);
        [self updateBlendMode];
    }
    return self;
}

- (id)initWithContentsOfFile:(NSString *)filename texture:(SPTexture *)texture
{
    if ((self = [self initWithTexture:texture]))
    {
        [self parseConfiguration:filename];
    }
    return self;
}

- (id)initWithContentsOfFile:(NSString*)filename
{
    return [self initWithContentsOfFile:filename texture:nil];
}

+ (id)particleSystemWithContentsOfFile:(NSString *)filename
{
    return [[self alloc] initWithContentsOfFile:filename];
}

- (id)copyWithZone:(NSZone *)zone
{
    SXParticleSystem *copy = [[[self class] allocWithZone:zone] initWithTexture:self.texture];
    copy.maxNumParticles = _maxNumParticles;
    
    copy->_emitterType = _emitterType;
    copy->_emitterX = _emitterX;
    copy->_emitterXVariance = _emitterXVariance;
    copy->_emitterY = _emitterY;
    copy->_emitterYVariance = _emitterYVariance;
    copy->_maxNumParticles = _maxNumParticles;
    copy->_lifespan = _lifespan;
    copy->_lifespanVariance = _lifespanVariance;
    copy->_startSize = _startSize;
    copy->_startSizeVariance = _startSizeVariance;
    copy->_endSize = _endSize;
    copy->_endSizeVariance = _endSizeVariance;
    copy->_emitAngle = _emitAngle;
    copy->_emitAngleVariance = _emitAngleVariance;
    copy->_speed = _speed;
    copy->_speedVariance = _speedVariance;
    copy->_gravityX = _gravityX;
    copy->_gravityY = _gravityY;
    copy->_radialAcceleration = _radialAcceleration;
    copy->_radialAccelerationVariance = _radialAccelerationVariance;
    copy->_tangentialAcceleration = _tangentialAcceleration;
    copy->_tangentialAccelerationVariance = _tangentialAccelerationVariance;
    copy->_maxRadius = _maxRadius;
    copy->_maxRadiusVariance = _maxRadiusVariance;
    copy->_minRadius = _minRadius;
    copy->_rotatePerSecond = _rotatePerSecond;
    copy->_rotatePerSecondVariance = _rotatePerSecondVariance;
    copy->_startColor = _startColor;
    copy->_startColorVariance = _startColorVariance;
    copy->_endColor = _endColor;
    copy->_endColorVariance = _endColorVariance;
    copy->_blendFuncSource = _blendFuncSource;
    copy->_blendFuncDestination = _blendFuncDestination;
    
    return copy;
}

- (void)dealloc
{
    free(_particles);
}

- (void)advanceTime:(double)passedTime
{
    // advance existing particles
    
    int particleIndex = 0;
    while (particleIndex < _numParticles)
    {
        // get the particle for the current particle index
        SXParticle *currentParticle = &_particles[particleIndex];
        
        // if the current particle is alive then update it
        if (currentParticle->timeToLive > passedTime)
        {
            [self advanceParticle:currentParticle byTime:passedTime];
            particleIndex++;
        }
        else
        {
            if (particleIndex != _numParticles - 1)
                _particles[particleIndex] = _particles[_numParticles - 1];
            
            _numParticles--;
            
            if (!_numParticles)
                [self dispatchEvent:[SPEvent eventWithType:SP_EVENT_TYPE_COMPLETED]];
        }
    }
    
    // create and advance new particles
    
    if (_burstTime > 0)
    {
        float timeBetweenParticles = _lifespan / _maxNumParticles;
        _frameTime += passedTime;
        while (_frameTime > 0)
        {
            [self addParticleWithElapsedTime:_frameTime];
            _frameTime -= timeBetweenParticles;
        }
        
        if (_burstTime != DBL_MAX)
            _burstTime = MAX(0.0, _burstTime - passedTime);
    }
    
    // update quad batch
    
    [_quadBatch reset];
    float baseSize = _texture.width;
    
    if (!_particleImage)
        [self updateParticleImage];
    
    for (int i=0; i<_numParticles; ++i)
    {
        SXParticle particle = _particles[i];
        SXColor4f color = particle.color;
        
        _particleImage.x = particle.x;
        _particleImage.y = particle.y;
        _particleImage.scaleX = _particleImage.scaleY = MAX(0.0f, particle.size / baseSize);
        _particleImage.alpha = color.alpha;
        _particleImage.color = SP_COLOR(SP_CLAMP(color.red,   0.0f, 1.0f) * 255,
                                        SP_CLAMP(color.green, 0.0f, 1.0f) * 255,
                                        SP_CLAMP(color.blue,  0.0f, 1.0f) * 255);
        
        [_quadBatch addQuad:_particleImage];
    }
}

- (void)advanceParticle:(SXParticle *)particle byTime:(double)passedTime
{
    passedTime = MIN(passedTime, particle->timeToLive);
    particle->timeToLive -= passedTime;
    
    if (_emitterType == SXParticleEmitterTypeRadial)
    {
        particle->rotation += particle->rotationDelta * passedTime;
        particle->radius   -= particle->radiusDelta   * passedTime;
        particle->x = _emitterX - cosf(particle->rotation) * particle->radius;
        particle->y = _emitterY - sinf(particle->rotation) * particle->radius;
        
        if (particle->radius < _minRadius)
            particle->timeToLive = 0;
    }
    else
    {
        float distanceX = particle->x - particle->startX;
        float distanceY = particle->y - particle->startY;
        float distanceScalar = MAX(0.01f, sqrtf(SQ(distanceX) + SQ(distanceY)));
        
        float radialX = distanceX / distanceScalar;
        float radialY = distanceY / distanceScalar;
        float tangentialX = radialX;
        float tangentialY = radialY;
        
        radialX *= particle->radialAcceleration;
        radialY *= particle->radialAcceleration;
        
        float newY = tangentialX;
        tangentialX = -tangentialY * particle->tangentialAcceleration;
        tangentialY = newY * particle->tangentialAcceleration;
        
        particle->velocityX += passedTime * (_gravityX + radialX + tangentialX);
        particle->velocityY += passedTime * (_gravityY + radialY + tangentialY);
        particle->x += particle->velocityX * passedTime;
        particle->y += particle->velocityY * passedTime;
    }
    
    particle->size += particle->sizeDelta * passedTime;
    
    // Update the particle's color
    particle->color.red   += particle->colorDelta.red   * passedTime;
    particle->color.green += particle->colorDelta.green * passedTime;
    particle->color.blue  += particle->colorDelta.blue  * passedTime;
    particle->color.alpha += particle->colorDelta.alpha * passedTime;
}

- (void)addParticleWithElapsedTime:(double)time
{
    if (_numParticles >= _maxNumParticles)
        return;
    
    float lifespan = RANDOM_VARIANCE(_lifespan, _lifespanVariance);
    if (lifespan <= 0.0f)
        return;
    
    SXParticle *particle = &_particles[_numParticles++];
    particle->timeToLive = lifespan;
    
    particle->x = RANDOM_VARIANCE(_emitterX, _emitterXVariance);
    particle->y = RANDOM_VARIANCE(_emitterY, _emitterYVariance);
    particle->startX = _emitterX;
    particle->startY = _emitterY;
    
    float angle = RANDOM_VARIANCE(_emitAngle, _emitAngleVariance);
    float speed = RANDOM_VARIANCE(_speed, _speedVariance);
    particle->velocityX = speed * cosf(angle);
    particle->velocityY = speed * sinf(angle);
    
    particle->radius = RANDOM_VARIANCE(_maxRadius, _maxRadiusVariance);
    particle->radiusDelta = _maxRadius / lifespan;
    particle->rotation = RANDOM_VARIANCE(_emitAngle, _emitAngleVariance);
    particle->rotationDelta = RANDOM_VARIANCE(_rotatePerSecond, _rotatePerSecondVariance);
    particle->radialAcceleration = RANDOM_VARIANCE(_radialAcceleration, _radialAccelerationVariance);
    particle->tangentialAcceleration = RANDOM_VARIANCE(_tangentialAcceleration, _tangentialAccelerationVariance);
    
    float particleStartSize  = MAX(0.1f, RANDOM_VARIANCE(_startSize, _startSizeVariance));
    float particleFinishSize = MAX(0.1f, RANDOM_VARIANCE(_endSize, _endSizeVariance));
    particle->size = particleStartSize;
    particle->sizeDelta = (particleFinishSize - particleStartSize) / lifespan;
    
    SXColor4f startColor = RANDOM_COLOR_VARIANCE(_startColor, _startColorVariance);
    SXColor4f endColor   = RANDOM_COLOR_VARIANCE(_endColor,   _endColorVariance);
    
    SXColor4f colorDelta;
    colorDelta.red   = (endColor.red   - startColor.red)   / lifespan;
    colorDelta.green = (endColor.green - startColor.green) / lifespan;
    colorDelta.blue  = (endColor.blue  - startColor.blue)  / lifespan;
    colorDelta.alpha = (endColor.alpha - startColor.alpha) / lifespan;
    
    particle->color = startColor;
    particle->colorDelta = colorDelta;
    
    [self advanceParticle:particle byTime:time];
}

- (void)render:(SPRenderSupport *)support
{
    [_quadBatch render:support];
}

- (void)start
{
    [self startBurst:DBL_MAX];
}

- (void)startBurst:(double)duration
{
    _burstTime = fabs(duration);
}

- (void)stop
{
    _burstTime = 0;
}

- (SPRectangle*)boundsInSpace:(SPDisplayObject*)targetCoordinateSpace
{
    // we return an empty rectangle (width and height are zero), but with the correct
    // values for x and y.
    
    SPMatrix *transformationMatrix = [self transformationMatrixToSpace:targetCoordinateSpace];
    SPPoint *transformedPoint = [transformationMatrix transformPointWithX:0.0f y:0.0f];
    return [SPRectangle rectangleWithX:transformedPoint.x y:transformedPoint.y
                                 width:0.0f height:0.0f];
}

#pragma mark XML parsing

- (void)parseConfiguration:(NSString *)path
{
    if (!path) return;
    
    _path = [SPUtils absolutePathToFile:path];
    if (!_path) [NSException raise:SP_EXC_FILE_NOT_FOUND format:@"file not found: %@", path];
    
    NSData *xmlData = [[NSData alloc] initWithContentsOfFile:_path];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xmlData];
    
    BOOL success = [parser parseElementsWithBlock:^(NSString *elementName, NSDictionary *attributes)
    {
        elementName = [elementName lowercaseString];
        
        if (!_texture && [elementName isEqualToString:@"texture"])
        {
            NSString *b64Data = [attributes valueForKey:@"data"];
            if (b64Data)
            {
                NSData *imageData = [[NSData dataWithBase64EncodedString:b64Data] gzipInflate];
                _texture = [[SPTexture alloc] initWithContentsOfImage:[UIImage imageWithData:imageData]];
            }
            else
            {
                NSString *filename = [attributes valueForKey:@"name"];
                NSString *folder = [_path stringByDeletingLastPathComponent];
                NSString *absolutePath = [folder stringByAppendingPathComponent:filename];
                _texture = [[SPTexture alloc] initWithContentsOfFile:absolutePath];
            }
        }
        else if ([elementName isEqualToString:@"sourcepositionvariance"])
        {
            _emitterXVariance = [[attributes objectForKey:@"x"] floatValue];
            _emitterYVariance = [[attributes objectForKey:@"y"] floatValue];
        }
        else if ([elementName isEqualToString:@"gravity"])
        {
            _gravityX = [[attributes objectForKey:@"x"] floatValue];
            _gravityY = [[attributes objectForKey:@"y"] floatValue];
        }
        else if ([elementName isEqualToString:@"emittertype"])
            _emitterType = (SXParticleEmitterType)[[attributes objectForKey:@"value"] intValue];
        else if ([elementName isEqualToString:@"maxparticles"])
            self.maxNumParticles = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"particlelifespan"])
            self.lifespan = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"particlelifespanvariance"])
            _lifespanVariance = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"startparticlesize"])
            _startSize = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"startparticlesizevariance"])
            _startSizeVariance = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"finishparticlesize"])
            _endSize = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"finishparticlesizevariance"])
            _endSizeVariance = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"angle"])
            _emitAngle = SP_D2R([[attributes objectForKey:@"value"] floatValue]);
        else if ([elementName isEqualToString:@"anglevariance"])
            _emitAngleVariance = SP_D2R([[attributes objectForKey:@"value"] floatValue]);
        else if ([elementName isEqualToString:@"speed"])
            _speed = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"speedvariance"])
            _speedVariance = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"radialacceleration"])
            _radialAcceleration = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"radialaccelvariance"])
            _radialAccelerationVariance = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"tangentialacceleration"])
            _tangentialAcceleration = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"tangentialaccelvariance"])
            _tangentialAccelerationVariance = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"maxradius"])
            _maxRadius = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"maxradiusvariance"])
            _maxRadiusVariance = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"minradius"])
            _minRadius = [[attributes objectForKey:@"value"] floatValue];
        else if ([elementName isEqualToString:@"rotatepersecond"])
            _rotatePerSecond = SP_D2R([[attributes objectForKey:@"value"] floatValue]);
        else if ([elementName isEqualToString:@"rotatepersecondvariance"])
            _rotatePerSecondVariance = SP_D2R([[attributes objectForKey:@"value"] floatValue]);
        else if ([elementName isEqualToString:@"startcolor"])
            _startColor = [self colorFromDictionary:attributes];
        else if ([elementName isEqualToString:@"startcolorvariance"])
            _startColorVariance = [self colorFromDictionary:attributes];
        else if ([elementName isEqualToString:@"finishcolor"])
            _endColor = [self colorFromDictionary:attributes];
        else if ([elementName isEqualToString:@"finishcolorvariance"])
            _endColorVariance = [self colorFromDictionary:attributes];
        else if ([elementName isEqualToString:@"blendfuncsource"])
            _blendFuncSource = [[attributes objectForKey:@"value"] intValue];
        else if ([elementName isEqualToString:@"blendfuncdestination"])
            _blendFuncDestination = [[attributes objectForKey:@"value"] intValue];
    }];
    
    if (!success)
        [NSException raise:SP_EXC_FILE_INVALID
                    format:@"could not parse emitter configuration %@. Error code: %d, domain: %@",
         path, parser.parserError.code, parser.parserError.domain];
    
    [self updateBlendMode];
}

- (SXColor4f)colorFromDictionary:(NSDictionary *)dictionary
{
    SXColor4f color;
    color.red   = [[dictionary objectForKey:@"red"]   floatValue];
    color.green = [[dictionary objectForKey:@"green"] floatValue];
    color.blue  = [[dictionary objectForKey:@"blue"]  floatValue];
    color.alpha = [[dictionary objectForKey:@"alpha"] floatValue];
    return color;
}

- (void)updateBlendMode
{
    self.blendMode = [SPBlendMode encodeBlendModeWithSourceFactor:_blendFuncSource
                                                       destFactor:_blendFuncDestination];
}

- (void)setBlendFuncSource:(uint)value
{
    _blendFuncSource = value;
    [self updateBlendMode];
}

- (void)setBlendFuncDestination:(uint)value
{
    _blendFuncDestination = value;
    [self updateBlendMode];
}

- (void)setLifespan:(float)value
{
    _lifespan = MAX(0.01, value);
}

- (void)setMaxNumParticles:(int)value
{
    _maxNumParticles = value;
    _numParticles = MIN(_maxNumParticles, _numParticles);
    _particles = realloc(_particles, sizeof(SXParticle) * value);
}

- (void)setTexture:(SPTexture *)texture
{
    if (_texture != texture)
    {
        _texture = texture;
        [self updateParticleImage];
    }
}

- (void)updateParticleImage
{
    if (!_particleImage)
        _particleImage = [[SPImage alloc] initWithTexture:_texture];
    else
    {
        _particleImage.texture = _texture;
        [_particleImage readjustSize];
    }
    
    _particleImage.premultipliedAlpha = NO; // that's how the original PD rendering works!
    _particleImage.pivotX = (int)(_texture.width / 2.0f);
    _particleImage.pivotY = (int)(_texture.height / 2.0f);
}

@end
