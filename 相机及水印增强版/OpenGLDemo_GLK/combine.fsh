precision mediump float;

uniform sampler2D Sampler;
uniform sampler2D textSampler;

uniform vec3 u_textColor;
uniform vec4 textRect;

varying vec2 texCoordVarying;

void main()
{
    if (textRect.x < texCoordVarying.x && textRect.x+textRect.z > texCoordVarying.x &&
        textRect.y < texCoordVarying.y && textRect.y+textRect.w > texCoordVarying.y) {
        
        //在文字的显示区域
        vec2 textCoord = vec2(texCoordVarying.x - textRect.x, texCoordVarying.y - textRect.y);
        
        textCoord = vec2(textCoord.x / textRect.z, textCoord.y / textRect.w);
        
        vec4 textColor = texture2D(textSampler, textCoord);
        if (length(textColor) > 0.5) {
            gl_FragColor = vec4(u_textColor, 1.0);
        } else {
            vec4 baseColor = texture2D(Sampler, texCoordVarying);
            gl_FragColor = baseColor;
        }
        
    } else {
        
        //摄像头内容显示的区域
        gl_FragColor = texture2D(Sampler, texCoordVarying);
    }
}
