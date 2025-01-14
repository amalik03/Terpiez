#include <flutter/runtime_effect.glsl>
precision mediump float;

// Inputs
uniform vec2 uResolution;
uniform float uTime;

// Outputs
out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / uResolution;
    float denom = 1.0;
    float blue = tan((st.x + st.y) * (uTime / denom));
    fragColor = vec4(0, 0, blue, 0.45);
}