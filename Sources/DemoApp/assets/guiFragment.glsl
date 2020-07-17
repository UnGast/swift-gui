#version 330 core

in vec2 inTexCoords;

uniform sampler2D compositionTexture;

out vec4 FragColor;

void main() {
    //FragColor = vec4((gl_FragCoord.x + 1) / 2, (gl_FragCoord.y + 1) / 2, 0, 1.0);
    FragColor = vec4(texture(compositionTexture, inTexCoords).rgb, 1.0);// +*/ vec4(gl_FragCoord.xy, 0, 1.0);
}