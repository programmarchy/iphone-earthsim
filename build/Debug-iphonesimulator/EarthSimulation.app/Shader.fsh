//
//  Shader.fsh
//  EarthSimulation
//
//  Created by Donald Ness on 12/17/10.
//  Copyright 2010 Circum. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
