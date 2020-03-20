attribute vec4 position;
attribute vec2 textureCoordinate;
//attribute vec4 positionColor;
uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

varying lowp vec2 varyTextCoord;

void main()
{
    varyTextCoord = textureCoordinate;
    
    vec4 vPos = position;

    vPos = projectionMatrix * modelViewMatrix * position;

    gl_Position = position;
}

