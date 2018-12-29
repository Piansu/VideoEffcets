varying vec2 varyTextCoord;

uniform sampler2D planarY;
uniform sampler2D planarU;
uniform sampler2D planarV;

const mat3 colorConversionMatrix = mat3(
                                        1.164,  1.164,  1.164,
                                        0.0,   -0.213,  2.112,
                                        1.793, -0.533,  0.0
                                        );

void main()
{
    vec2 cood = vec2(varyTextCoord.x, 1.0 - varyTextCoord.y);
    float y = texture2D(planarY, cood).r - (16.0 / 255.0);
    float u = texture2D(planarU, cood).r - 0.5;
    float v = texture2D(planarV, cood).r - 0.5;
    
    vec3 rgb = colorConversionMatrix * vec3(y, u, v);
    
    gl_FragColor = vec4(rgb, 1.0);
    
}
