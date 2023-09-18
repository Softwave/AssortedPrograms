/*
 * Particle System with OpenGL using the GPU for physics calculations
 * (c) 2023 by Jessica Leyba
 * softwave.com
*/

#include <iostream>
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp> // vec3, vec4, ivec4, mat4
#include <glm/gtc/matrix_transform.hpp>                       
#include <glm/gtc/type_ptr.hpp> // value_ptr
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h> // offsetof
#include <vector>

// Variables 
const int SCREEN_WIDTH = 1600;
const int SCREEN_HEIGHT = 900;
const int PARTICLE_COUNT = 25000;
// Simulation constants
const float GRAVITY = -0.1f;


struct Particle
{
    glm::vec3 position;
    glm::vec3 velocity;
    glm::vec3 color;
    float mass;
};

Particle *particles;

// CUDA kernel for calculating particle positions 
__global__ void updateParticles(Particle* particles, int n)
{
const float G = 6.67430e-07; 
    int index = threadIdx.x + blockIdx.x * blockDim.x;
    if (index < n)
    {
        float Fgx = 0.0f, Fgy = 0.0f, Fgz = 0.0f;

        for (int j = 0; j < n; j++)
        {
            if (index != j)
            {
                float dx = particles[j].position.x - particles[index].position.x;
                float dy = particles[j].position.y - particles[index].position.y;
                float dz = particles[j].position.z - particles[index].position.z;

                float distSqr = dx*dx + dy*dy + dz*dz;
                 // Add softening to avoid infinities
                float dist = sqrt(distSqr) + 0.0051f;

                float force = G / distSqr;

                Fgx += force * dx / dist;
                Fgy += force * dy / dist;
                Fgz += force * dz / dist;
            }
        }

        particles[index].velocity.x += Fgx * particles[index].mass;
        particles[index].velocity.y += Fgy * particles[index].mass;
        particles[index].velocity.z += Fgz * particles[index].mass;

        particles[index].position.x += particles[index].velocity.x;
        particles[index].position.y += particles[index].velocity.y;
        particles[index].position.z += particles[index].velocity.z;

        // Add some spin like a galaxy
        particles[index].velocity.x += particles[index].position.y * 0.00008f;
        particles[index].velocity.y -= particles[index].position.x * 0.00008f;
        

        // Set color based on position
        particles[index].color.x = (particles[index].position.x + 2.0f) / 2.0f;
        particles[index].color.y = (particles[index].position.y + 1.0f) / 2.0f;
        particles[index].color.z = (particles[index].position.z + 2.0f) / 2.0f;

        //Add to color based on the inverse of the distance from the center
        float dist = sqrt(particles[index].position.x * particles[index].position.x + particles[index].position.y * particles[index].position.y + particles[index].position.z * particles[index].position.z);
        particles[index].color.x += 1.0f / dist;
        particles[index].color.y += 1.0f / dist;
        particles[index].color.z += 1.0f / dist;
    }
}


char* loadShaderSource(const char* filepath)
{
    FILE* file = fopen(filepath, "rb");
    if (!file)
    {
        fprintf(stderr, "Error: Could not open shader file %s\n", filepath);
        return NULL;
    }

    // Go to the end of the file to determine its size
    fseek(file, 0, SEEK_END);
    long filesize = ftell(file);
    fseek(file, 0, SEEK_SET);

    // Allocate buffer for the source code and read it in
    char* buffer = (char*)malloc(filesize + 1);  // +1 for null terminator
    if (!buffer)
    {
        fprintf(stderr, "Error: Could not allocate memory for shader source\n");
        fclose(file);
        return NULL;
    }
    
    fread(buffer, 1, filesize, file);
    buffer[filesize] = '\0';  // Null-terminate the buffer

    fclose(file);
    return buffer;
}


int main(void)
{
    // Initialise GLFW
    if (!glfwInit())
    {
        fprintf(stderr, "Error: Could not initialise GLFW\n");
        return -1;
    }

    // Open a window and create its OpenGL context
    GLFWwindow* window = glfwCreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Big Bang", NULL, NULL);
    if (!window)
    {
        fprintf(stderr, "Error: Could not open window\n");
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    // Init GLEW
    glewExperimental = GL_TRUE;
    if (glewInit() != GLEW_OK)
    {
        fprintf(stderr, "Error: Could not initialise GLEW\n");
        glfwTerminate();
        return -1;
    }

    particles = new Particle[PARTICLE_COUNT];
    // Setup simulation
    



    
    // Load and compile shaders
    char* vertexShaderSource = loadShaderSource("vert.glsl");
    char* fragmentShaderSource = loadShaderSource("frag.glsl");
    char* computeShaderSource = loadShaderSource("compute.glsl");

    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    //GLuint computeShader = glCreateShader(GL_COMPUTE_SHADER);

    glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
    //glShaderSource(computeShader, 1, &computeShaderSource, NULL);

    GLint success;
    GLchar infoLog[512];
    glCompileShader(vertexShader);
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if(!success)
    {
        glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
        std::cerr << "Vertex Shader Compilation Failed\n" << infoLog << std::endl;
    }
    
    glCompileShader(fragmentShader);
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if(!success) {
        glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
        std::cerr << "Fragment Shader Compilation Failed\n" << infoLog << std::endl;
    }

    GLuint shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    glUseProgram(shaderProgram);

    // Initialise particle data
    for (int i = 0; i < PARTICLE_COUNT; i++)
    {
        // Position in a sphere
        float theta = (float)rand() / RAND_MAX * 2 * M_PI;
        float phi = (float)rand() / RAND_MAX * 2 * M_PI;
        float r = (float)rand() / RAND_MAX * 0.5f + 0.5f;
        particles[i].position.x = r * sin(theta) * cos(phi);
        particles[i].position.y = r * sin(theta) * sin(phi);
        particles[i].position.z = r * cos(theta); 

        // Random mass between 0.5 and 1.5
        particles[i].mass = (float)rand() / RAND_MAX + 0.5f;
    }

    // Buffer particle data to GPU
    GLuint particleBuffer;
    glGenBuffers(1, &particleBuffer);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, particleBuffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, PARTICLE_COUNT * sizeof(Particle), particles, GL_DYNAMIC_DRAW);

    
    // Setup Rendering Params (VAOs, VBOs, etc)
    GLuint particleVBO;
    glGenBuffers(1, &particleVBO);
    glBindBuffer(GL_ARRAY_BUFFER, particleVBO);
    glBufferData(GL_ARRAY_BUFFER, PARTICLE_COUNT * sizeof(Particle), particles, GL_DYNAMIC_DRAW);
    GLuint particleVAO;
    glGenVertexArrays(1, &particleVAO);
    glBindVertexArray(particleVAO);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Particle), (GLvoid*)offsetof(Particle, position));
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(Particle), (GLvoid*)offsetof(Particle, velocity));
    glEnableVertexAttribArray(1);
    // Color
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, sizeof(Particle), (GLvoid*)offsetof(Particle, color));
    glEnableVertexAttribArray(2);
  
    glUseProgram(shaderProgram);

    // Projection and model and view matrices
    glm::mat4 projectionMatrix = glm::perspective(45.0f, (float)SCREEN_WIDTH / (float)SCREEN_HEIGHT, 0.1f, 100.0f);
    glm::vec3 cameraPos = glm::vec3(0.0f, 0.0f, 3.0f); // Position of the camera in the world
    glm::vec3 cameraTarget = glm::vec3(0.0f, 0.0f, 0.0f); // The point in the world the camera is looking at
    glm::vec3 upVector = glm::vec3(0.0f, 1.0f, 0.0f); 
    glm::mat4 viewMatrix = glm::lookAt(cameraPos, cameraTarget, upVector);
    glm::mat4 modelMatrix = glm::mat4(1.0f);
    // Combined model view projection matrix
    glm::mat4 mvpMatrix = projectionMatrix * viewMatrix * modelMatrix;
    
    GLint uMVPMatrixLocation = glGetUniformLocation(shaderProgram, "uMVPMatrix");
    glUniformMatrix4fv(uMVPMatrixLocation, 1, GL_FALSE, glm::value_ptr(mvpMatrix));
    glBindVertexArray(particleVAO);

    // CUDA setup
    Particle* d_particles;
    size_t size = PARTICLE_COUNT * sizeof(Particle);
    cudaError_t err;
    cudaMalloc(&d_particles, size);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "Error: Could not allocate memory on GPU\n");
        return -1;
    }

    // Delta time
    float dt = 0.0f;
    
    // Draw
    while (!glfwWindowShouldClose(window))
    {
        // Clear the screen
        glClear(GL_COLOR_BUFFER_BIT);
        

        // Draw particles
        glDrawArrays(GL_POINTS, 0, PARTICLE_COUNT);

        // Copy data from CPU to GPU
        cudaMemcpy(d_particles, particles, size, cudaMemcpyHostToDevice);

        
        dt = glfwGetTime();
        // Launch CUDA kernel to update particles
        int threadsPerBlock = 256;
        int blocksPerGrid = (PARTICLE_COUNT + threadsPerBlock - 1) / threadsPerBlock;
        updateParticles<<<blocksPerGrid, threadsPerBlock>>>(d_particles, PARTICLE_COUNT);
        // Wait for kernel to finish
        cudaDeviceSynchronize();
        // Copy data back from GPU to CPU
        cudaMemcpy(particles, d_particles, size, cudaMemcpyDeviceToHost);
        // Free GPU memory

        // Update GPU Buffer
        glBindBuffer(GL_ARRAY_BUFFER, particleVBO);
        glBufferSubData(GL_ARRAY_BUFFER, 0, PARTICLE_COUNT * sizeof(Particle), particles);

        glPointSize(4.0f);
        glDrawArrays(GL_POINTS, 0, PARTICLE_COUNT);

        // Swap buffers
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    // Cleanup
    cudaFree(d_particles);
    

    
    return 0;
}



