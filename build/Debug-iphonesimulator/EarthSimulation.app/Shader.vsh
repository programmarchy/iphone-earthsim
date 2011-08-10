//
//  Shader.vsh
//  EarthSimulation
//
//  Created by Donald Ness on 12/17/10.
//  Copyright 2010 Circum. All rights reserved.
//

attribute vec4 position;
attribute vec4 color;

varying vec4 colorVarying;

uniform float translate;

void main()
{
    gl_Position = position;
    gl_Position.y += sin(translate) / 2.0;

    colorVarying = color;
}
