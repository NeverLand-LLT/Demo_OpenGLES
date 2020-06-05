attribute vec4 position;
attribute vec2 textureCoordinate;
uniform mat4 rotateMatrix;

varying lowp vec2 varyTextCoord;

void main()
{
    varyTextCoord = textureCoordinate;
    
    vec4 vPos = position;

    vPos = vPos * rotateMatrix;

    gl_Position = vPos;
}

