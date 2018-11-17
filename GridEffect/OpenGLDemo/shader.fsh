varying lowp vec2 varyCoord;

uniform sampler2D colorMap;

void main()
{
    gl_FragColor = texture2D(colorMap, varyCoord);
}



