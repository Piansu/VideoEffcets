attribute vec3 position;
attribute vec2 coordinate;

uniform mat4 rotateMatrix;
uniform highp float time;

varying lowp vec2 varyCoord;

void main()
{
    varyCoord = coordinate;
    
    float fractTime = fract(time);
    
    float zPosition = smoothstep(0.0, 1.0, 0.5+position.z - fractTime);
    
    gl_Position = rotateMatrix * vec4(position.x, position.y, zPosition, 1.0);
}
