precision mediump float;

uniform sampler2D colorMap;

uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

varying lowp vec2 varyTextCoord;
varying highp vec3 varyNormal;
varying highp vec3 varyEye;

struct Light
{
    vec3 direction;
    vec3 ambientColor;
    vec3 diffuseColor;
    vec3 specularColor;
};

//Light light = {
//    .direction = { 0.13, 0.72, 0.68 },
//    .ambientColor = { 0.05, 0.05, 0.05 },
//    .diffuseColor = { 0.9, 0.9, 0.9 },
//    .specularColor = { 1, 1, 1 }
//};

struct Material
{
    vec3 ambientColor;
    vec3 diffuseColor;
    vec3 specularColor;
    float specularPower;
};

//    struct Material material = {
//        .ambientColor = { 0.9, 0.1, 0 },
//        .diffuseColor = { 0.9, 0.1, 0 },
//        .specularColor = { 1, 1, 1 },
//        .specularPower = 100
//    };

void main()
{
    vec3 baseColor = texture2D(colorMap, varyTextCoord).rgb;
    vec3 ambientTerm = vec3(0.05) * baseColor;

    vec3 normal = normalize(varyNormal);
    float diffuseIntensity = clamp(dot(normal, vec3(0.13, 0.72, 0.68)), 0.0, 1.0);
    vec3 diffuseTerm = vec3(1.0) * baseColor * diffuseIntensity;
    
    vec3 specularTerm = vec3(0);
    if (diffuseIntensity > 0.0)
    {
        vec3 eyeDirection = normalize(varyEye);
        vec3 halfway = normalize(vec3(0.13, 0.72, 0.68) + eyeDirection);
        float specularFactor = pow(clamp(dot(normal, halfway), 0.0, 1.0), 80.0);
        specularTerm = vec3(0.2) * vec3(1, 1, 1) * specularFactor;
    }
    
    gl_FragColor = vec4(ambientTerm + diffuseTerm + specularTerm, 1);
//    gl_FragColor = vec4(baseColor, 1.0);
}
