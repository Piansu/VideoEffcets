attribute vec4 position;
attribute vec2 texCoord;

varying vec2 texCoordVarying;

void main()
{
    gl_Position = position;
    texCoordVarying = vec2(texCoord.x, 1.0 - texCoord.y);
}

