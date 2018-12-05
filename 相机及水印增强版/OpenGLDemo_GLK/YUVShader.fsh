precision mediump float;
uniform sampler2D Sampler;
varying highp vec2 texCoordVarying;

void main()
{
    gl_FragColor = texture2D(Sampler, texCoordVarying);
}
