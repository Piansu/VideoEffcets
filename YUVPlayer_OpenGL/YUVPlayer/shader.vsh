attribute vec4 position;
attribute vec2 coordinate;

uniform mat4 rotateMatrix;

varying vec2 varyTextCoord;

void main()
{
    varyTextCoord = coordinate;
    
    gl_Position = rotateMatrix * position;
}
