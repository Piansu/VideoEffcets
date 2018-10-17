attribute vec4 position;
attribute vec2 coordinate;

uniform mat4 rotateMatrix;
uniform float strength;

varying lowp float v_strength;

varying lowp vec2 varyTextCoord;

void main()
{
    v_strength = strength;
    varyTextCoord = coordinate;
    
    vec4 vPos = position;

    vPos = rotateMatrix * vPos;
    gl_Position = vPos;
}

