attribute vec4 position;
attribute vec2 coordinate;

uniform mat4 rotateMatrix;
uniform highp float time;

varying lowp vec2 varyUVCoord; //纹理的 uv 坐标
varying lowp vec2 varyCoord; //顶点的显示区域坐标

void main()
{
    varyUVCoord = coordinate;
    varyCoord = vec2(position.zw);
    
    //小数部分
//    float offset = -fract(position.z) * 3.14159 * 2.0;
//
//    //旋转角度
//    float rotate = offset + time;
//    rotate = min(3.14159 * 2.0, rotate);
//    rotate = max(0.0, rotate);
//
//    float row = floor(position.z);
//
//    float ynoraml = (row-2.0) * 0.5 + 0.25;
//
//    float x = (position.x - ynoraml) * cos(rotate) + ynoraml;
//    float y = position.y;
//    float z = (position.x - ynoraml) * sin(rotate) + ynoraml;
    
    gl_Position = vec4(position.x, position.y, 0, 1);
    
}


