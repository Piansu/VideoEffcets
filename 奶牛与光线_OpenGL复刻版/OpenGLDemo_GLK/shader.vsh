attribute vec3 position;
attribute vec2 coordinate;
attribute vec3 normal;

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

varying lowp vec2 varyTextCoord;
varying highp vec3 varyNormal;
varying highp vec3 varyEye;

void main()
{
    varyTextCoord = coordinate;
    varyNormal = (modelMatrix * vec4(normal, 1.0)).xyz;
    varyEye = -(viewMatrix * modelMatrix * vec4(position, 1.0)).xyz;
    
    vec4 vPos = vec4(position, 1.0);

    vPos = projectionMatrix * viewMatrix * modelMatrix * vPos;
    
    gl_Position = vPos;
}
