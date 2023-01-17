# Raytracing using Compute Shaders! (Updated to Godot 4 beta 13)

## Relevant files

-   The raytracing compute shader is [`RayTracer.glsl`](/BasicComputeShader/RayTracer.glsl)
-   [`ray_tracer_simple.gd`](/BasicComputeShader/ray_tracer_simple.gd) contains:
    -   Code to setup a new compute pipeline
    -   Create storage buffers and texture buffers in a uniform set
    -   Encode the buffer data as bytes and add them to the buffer
    -   Dispatch the compute shader (specifying the number of workgroups)
    -   Read back output data from relevant buffers
-   Finally, [`ComputeOutput.gd`](/BasicComputeShader/ComputeOutput.gd) takes texture data as bytes and displays it on a `TextureRect` node
    -   This is used to display the compute output on screen

## IMPORTANT Note

The current implementation is a (terrible) GLSL port of the articles made by [David Kuri](http://blog.three-eyed-games.com/2018/05/03/gpu-ray-tracing-in-unity-part-1/).

I am aware that the raytracer doesn't look great right now. I will push updates to this repository whenever I'm able to fix it.

For now, please use this repository as a reference or a learning resource to understand how to make Compute Shaders in Godot 4!

## YouTube video (includes code explanation)

[![Watch the video](https://img.youtube.com/vi/ueUMr92GQJc/maxresdefault.jpg)](https://youtu.be/ueUMr92GQJc)

## References and Resources

Kuri, D. (2018, May 3). _GPU Ray Tracing in Unity – Part 1_. Three Eyed Games. [http://blog.three-eyed-games.com/2018/05/03/gpu-ray-tracing-in-unity-part-1/](http://blog.three-eyed-games.com/2018/05/03/gpu-ray-tracing-in-unity-part-1/)

Möller, T., & Trumbore, B. (1997). _Fast, Minimum Storage Ray-Triangle Intersection_. Program of Computer Graphics. [https://fileadmin.cs.lth.se/cs/Personal/Tomas_Akenine-Moller/pubs/raytri_tam.pdf](https://fileadmin.cs.lth.se/cs/Personal/Tomas_Akenine-Moller/pubs/raytri_tam.pdf)

Scratchapixel. (2014, August 15). _Ray-Tracing a Polygon Mesh (Ray-Tracing a Polygon Mesh (Part 2))_. [https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-polygon-mesh/ray-tracing-polygon-mesh-part-2](https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-polygon-mesh/ray-tracing-polygon-mesh-part-2)

Whitaker, R. B. (2009, January 21). _Creating a Specular Lighting Shader_. RB Whitaker’s Wiki. [http://rbwhitaker.wikidot.com/specular-lighting-shader](http://rbwhitaker.wikidot.com/specular-lighting-shader)

## My Socials

<p align="center">
	<a href="https://www.youtube.com/channel/UCD7K_FECPHTF0z5okAVlh0g/featured" target="blank"><img src="https://img.shields.io/badge/NekotoArts-%23FF0000.svg?style=for-the-badge&logo=YouTube&logoColor=white" alt="NekotoArts" /></a>
	<a href="https://twitter.com/NekotoArts" target="blank"><img src="https://img.shields.io/badge/NekotoArts-%231DA1F2.svg?style=for-the-badge&logo=Twitter&logoColor=white" alt="NekotoArts" /></a>
	<a href="https://nekotoarts.itch.io/" target="blank"><img src="https://img.shields.io/badge/Itch-%23FF0B34.svg?style=for-the-badge&logo=Itch.io&logoColor=white" /></a>
	<a href="https://ko-fi.com/nekoto" target="blank"><img src="https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white" /></a>
	<a href="https://godotshaders.com/author/nekotoarts/" target="blank"><img src="https://img.shields.io/badge/Godot_Shaders-%23FFFFFF.svg?style=for-the-badge&logo=godot-engine" /></a>
	<a href="https://reddit.com/user/XDGregory" target="blank"><img src="https://img.shields.io/badge/Reddit-FF4500?style=for-the-badge&logo=reddit&logoColor=white" /></a>
</p>

If you like my stuff, consider a sub to my [channel](https://www.youtube.com/channel/UCD7K_FECPHTF0z5okAVlh0g)?
