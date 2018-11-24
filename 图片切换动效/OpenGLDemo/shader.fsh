uniform sampler2D colorMap;
uniform sampler2D replaceMap;

uniform highp float time;

varying lowp vec2 varyUVCoord;
varying highp vec2 varyCoord; //顶点的显示区域坐标

const lowp float rowNum = 10.0;

void main()
{
    highp float l = 1.0 / rowNum;
    highp float duration = .5;
    highp float speed = l / duration;
    
    highp float row = varyCoord.x;
    highp float clumn = varyCoord.y;
    
    highp float piece = 1.0 / rowNum;
    
    highp float diff = -(0.01 * (clumn) + 0.01 * (row));

    highp float disdance = varyUVCoord.x + clamp(speed * time + diff, 0.0, 1.0);
    
    highp float xOffset = (float(clumn) * piece + 0.1);
    
    if (disdance > xOffset) {
        
        gl_FragColor = texture2D(replaceMap, vec2(varyUVCoord.x + clamp(speed * time, 0.0, piece) - piece, varyUVCoord.y) );
        
    } else {
        gl_FragColor = texture2D(colorMap, vec2(disdance, varyUVCoord.y));
    }
}
