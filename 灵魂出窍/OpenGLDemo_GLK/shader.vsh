attribute vec4 position;
attribute vec2 coordinate;

uniform mat4 rotateMatrix;

varying lowp vec2 varyTextCoord;

void main()
{
    varyTextCoord = coordinate;
    
    vec4 vPos = position;

    vPos = rotateMatrix * vPos;
    gl_Position = vPos;
}
