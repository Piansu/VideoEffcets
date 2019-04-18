varying lowp vec2 varyTextCoord;

uniform sampler2D colorMap;

void main()
{
    highp float M_PI = 3.14159265358979323846264338327950288;
    
    lowp vec2 samplePosion = (varyTextCoord - 0.5 ) * 2.0;
    
    lowp float radius = length(samplePosion);
    
    lowp float theta = atan(samplePosion.y / samplePosion.x);  // (-PI/2 ~ PI/2)
    
    lowp float piece = (theta + M_PI / 2.0 ) / (M_PI * 2.0);  // (0 ~ 0.5)
    
    piece = (samplePosion.x >= 0.0) ? piece + 0.5 : piece; //samplePosion.x > 0 时 (0.5 ~ 1.0)
    
    lowp vec2 newPosition = vec2(piece, radius * 0.65);
    
    gl_FragColor = texture2D(colorMap, newPosition);
}
