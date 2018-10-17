precision mediump float;

varying lowp vec2 varyTextCoord;
varying highp float v_strength;
uniform sampler2D colorMap;

void main()
{
    vec2 gid = vec2(varyTextCoord);
    
    highp float maxcolumn = 600.0;
    highp float mincolumn = 100.0;
    highp float column = maxcolumn - (maxcolumn - mincolumn) * (v_strength * 16.0);
    
    int tmpCol = int(gid.y * column);
    int index = tmpCol - tmpCol / 2 * 2;
    if (index == 0) {
        gid.x += v_strength;
    } else {
        gid.x -= v_strength;
    }
    
    gl_FragColor = texture2D(colorMap, gid);
}
