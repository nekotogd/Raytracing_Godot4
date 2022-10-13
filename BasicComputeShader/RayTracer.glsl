#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer CameraData {
	mat4 CameraToWorld;
	float CameraFOV;
	float CameraFarPlane;
	float CameraNearPlane;
}
camera_data;

layout(set = 0, binding = 1, std430) restrict buffer DirectionalLight {
	vec4 data;
}
directional_light;

layout(rgba32f, binding = 2) uniform image2D rendered_image;

layout(set = 0, binding = 3, std430) restrict buffer Params {
	float time;
}
params;

// Structs for RayTracing
struct Sphere {
	vec3 center;
	float radius;
	vec3 albedo;
	vec3 specular;
};

struct Ray {
	vec3 origin;
	vec3 direction;
	vec3 energy;
};

struct RayHit
{
    vec3 position;
    float dist;
    vec3 normal;
	vec3 color;
	vec3 specular;
};

// Global Constants
const float PI = 3.14159265;
const float INF = 99999999.0;
const vec3 sky_color = vec3(0.671, 0.851, 1.0);
const int MAX_REFLECTION_ITERATIONS = 7;
const float specularity = 0.5;
const int grid_length = 3;

// Helper Functions ==============================================================
float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// We cannot retrieve the projection matrix from a camera in GDScript
// ...instead I passed the camera info to the shader and reconstructed the projection matrix
mat4 BasicProjectionMatrix(float fov_deg, float far_plane, float near_plane)
{
	// What? You think this is bad variable naming?
	// You haven't even seen my other shaders yet, hehe
	float S = 1.0 / tan(radians(fov_deg / 2.0));
	float mfbfmn = (-far_plane) / (far_plane - near_plane);
	float mfinbfmn = -(far_plane * near_plane) / (far_plane - near_plane);

	mat4 proj_mat = mat4(
		vec4(S, 0.0, 0.0, 0.0),
		vec4(0.0, S, 0.0, 0.0),
		vec4(0.0, 0.0, mfbfmn, -1.0),
		vec4(0.0, 0.0, mfinbfmn, 0.0)
	);

	return proj_mat;
}
// End Helper Functions ==============================================================

Ray CreateRay(vec3 origin, vec3 direction)
{
    Ray ray;
    ray.origin = origin;
    ray.direction = direction;
	ray.energy = vec3(1.0);
    return ray;
}

Ray CreateCameraRay(vec2 uv)
{
	mat4 _CameraToWorld = camera_data.CameraToWorld;
	mat4 _CameraInverseProjection = inverse(BasicProjectionMatrix(camera_data.CameraFOV, camera_data.CameraFarPlane, camera_data.CameraNearPlane));

    // Transform the camera origin to world space
    vec3 origin = _CameraToWorld[3].xyz;
    
    // Invert the perspective projection of the view-space position
    vec3 direction = (_CameraInverseProjection * vec4(uv, 0.0, 1.0)).xyz;
    // Transform the direction from camera to world space and normalize
    direction = (_CameraToWorld * vec4(direction, 0.0)).xyz;
    direction = normalize(direction);
    return CreateRay(origin, direction);
}

RayHit CreateRayHit()
{
    RayHit hit;
    hit.position = vec3(0.0);
    hit.dist = INF;
    hit.normal = vec3(0.0);
	hit.specular = vec3(0.0);
	hit.color = vec3(0.0);
    return hit;
}

void IntersectGroundPlane(Ray ray, inout RayHit bestHit)
{
    // Calculate distance along the ray where the ground plane is intersected
    float t = -ray.origin.y / ray.direction.y;
    if (t > 0 && t < bestHit.dist)
    {
        bestHit.dist = t;
        bestHit.position = ray.origin + t * ray.direction;
        bestHit.normal = vec3(0.0, 1.0, 0.0);
		bestHit.color = vec3(0.8);
		bestHit.specular = vec3(0.5);
    }
}

void IntersectSphere(Ray ray, inout RayHit bestHit, Sphere sphere)
{
	// Avoid self-shadowing
	if (distance(sphere.center, ray.origin) < sphere.radius + 0.001)
	{
		return;
	}

    // Calculate distance along the ray where the sphere is intersected
    vec3 d = ray.origin - sphere.center;
    float p1 = -dot(ray.direction, d);
    float p2sqr = p1 * p1 - dot(d, d) + sphere.radius * sphere.radius;
    if (p2sqr < 0.0)
        return;
    float p2 = sqrt(p2sqr);
    float t = p1 - p2 > 0.0 ? p1 - p2 : p1 + p2;

	// Successful Hit
    if (t > 0.0 && t < bestHit.dist)
    {
        bestHit.dist = t;
        bestHit.position = ray.origin + t * ray.direction;
        bestHit.normal = normalize(bestHit.position - sphere.center);
		bestHit.color = sphere.albedo;
		bestHit.specular = sphere.specular;
    }
}

Sphere[grid_length * 2 * grid_length * 2] InstanceSpheres()
{
	Sphere[grid_length * 2 * grid_length * 2] objects;
	int i = 0;

	for (int x = -grid_length; x < grid_length; x++)
	{
		for (int y = -grid_length; y < grid_length; y++)
		{
			vec2 pos = vec2(x,y) / grid_length;
			pos *= 1.3; // spacing
			float h_rand = random(pos);
			float offset = sin(params.time + h_rand) * 0.7;
			offset -= 2.0;

			Sphere sphere;
			sphere.center = vec3(pos.x, 0.5 * h_rand + offset, pos.y - 3.0);
			sphere.radius = 0.2;
			sphere.albedo.r = random(sphere.center.xz);
			sphere.albedo.g = random(sphere.center.zx);
			sphere.albedo.b = random(sphere.center.xx);
			sphere.specular = vec3(specularity);

			objects[i] = sphere;
			i += 1;
		}
	}
	return objects;
}

RayHit Trace(Ray ray, Sphere[grid_length * 2 * grid_length * 2] objects)
{
    RayHit bestHit = CreateRayHit();
    // IntersectGroundPlane(ray, bestHit);

	for (int i = 0; i < grid_length * 2 * grid_length * 2; i++)
	{
		Sphere sphere = objects[i];
		IntersectSphere(ray, bestHit, sphere);
	}
    return bestHit;
}

vec3 Shade(inout Ray ray, RayHit hit, Sphere[grid_length * 2 * grid_length * 2] objects)
{
    if (hit.dist < INF)
    {
        // Reflect the ray and multiply energy with specular reflection
        ray.origin = hit.position + hit.normal * 0.001;
        ray.direction = reflect(ray.direction, hit.normal);
        ray.energy *= hit.specular;

		// Fix light direction
		vec3 light_direction = directional_light.data.xyz;
		light_direction.y *= -1.0;
		
		// Shadow test ray
		bool shadow = false;
		Ray shadowRay = CreateRay(hit.position + hit.normal * 0.001, -light_direction);
		RayHit shadowHit = Trace(shadowRay, objects);
		if (shadowHit.dist != INF)
		{
			return vec3(0.0);
		}

        // Return a diffuse-shaded color
		// Basically a mini fragment shader calculation goes on here
		float NdotL = dot(hit.normal, light_direction);
		vec3 diffuse = hit.color * clamp(-NdotL, 0.0, 1.0);
		diffuse *= directional_light.data.w; // Multiply by light intensity

		vec3 view = normalize(ray.direction) * vec3(1.0, 1.0, -1.0);
		vec3 r = normalize(2.0 * NdotL * hit.normal - light_direction);
		float RdotV = dot(r, view);
		float shininess = 50.0;
		float _spec = max(pow(RdotV, shininess), 0.0);
		return diffuse + vec3(_spec);
    }
    else
    {
        // Erase the ray's energy - the sky doesn't reflect anything
        ray.energy = vec3(0.0);
		// Return Sky color
        return sky_color;
    }
}

void main()
{
	// base pixel colour for image
	vec4 pixel = vec4(0.0, 0.0, 0.0, 1.0);
	
	ivec2 image_size = imageSize(rendered_image);
	// Coords in the range [-1,1]
	vec2 uv = vec2((gl_GlobalInvocationID.xy) / vec2(image_size) * 2.0 - 1.0);
	float aspect_ratio = float(image_size.x) / float(image_size.y);
	uv.x *= aspect_ratio;

	Sphere[grid_length * 2 * grid_length * 2] objects = InstanceSpheres();

	// Raytracing!
	Ray ray = CreateCameraRay(uv);
	vec3 result = vec3(0.0, 0.0, 0.0);
	for (int i = 0; i < MAX_REFLECTION_ITERATIONS + 1; i++)
	{
		RayHit hit = Trace(ray, objects);
		result += ray.energy * Shade(ray, hit, objects);
		if (!any(bvec3(ray.energy)))
			break;
	}
	pixel.xyz = result;

	// output to a specific pixel in the image buffer
	// Writes to texture
	imageStore(rendered_image, ivec2(gl_GlobalInvocationID.xy), pixel);
}
