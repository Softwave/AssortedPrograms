#version 430

layout(location = 0) in vec3 inPosition; // x y z 
layout(location = 1) in vec3 inVelocity; // vx, vy, vz
layout(location = 2) in vec3 inColor;

uniform mat4 uMVPMatrix;

out vec3 fColor;;

void main()
{
    fColor = inColor;
    gl_Position = uMVPMatrix * vec4(inPosition, 1.0);
}
