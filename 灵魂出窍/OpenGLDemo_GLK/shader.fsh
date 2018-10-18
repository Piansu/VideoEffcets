precision mediump float;

varying lowp vec2 varyTextCoord;

uniform sampler2D colorMap;
uniform mediump float strength;

void main()
{
    float maxStrength = 1.5;
    int stage = int((maxStrength - strength) * 10.0);
    
    vec4 baseColor = texture2D(colorMap, varyTextCoord);
  
    vec2 soulCoord1 = (varyTextCoord - vec2(0.5)) / strength + vec2(0.5);
    vec2 soulCoord2 = (varyTextCoord - vec2(0.5)) / (strength * strength) + vec2(0.5);
    vec2 soulCoord3 = (varyTextCoord - vec2(0.5)) / (strength * strength * strength) + vec2(0.5);
    vec2 soulCoord4 = (varyTextCoord - vec2(0.5)) / (strength * strength * strength * strength) + vec2(0.5);

    vec4 soulColor1 = texture2D(colorMap, soulCoord1);
    vec4 soulColor2 = texture2D(colorMap, soulCoord2);
    vec4 soulColor3 = texture2D(colorMap, soulCoord3);
    vec4 soulColor4 = texture2D(colorMap, soulCoord4);

    vec3 tmpColor = baseColor.rgb * 0.4 + soulColor1.rgb * 0.3 + soulColor2.rgb * 0.2 + soulColor3.rgb * 0.1;

    gl_FragColor = vec4(tmpColor, 1.0);
    
}
