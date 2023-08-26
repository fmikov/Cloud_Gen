#version 330 core

layout(location = 0) out vec4 color;

uniform sampler2D u_Texture;
uniform vec2 u_Resolution;
uniform float u_Aspect;
uniform vec3 u_CameraPos;
uniform vec3 u_CameraFront;
uniform vec3 u_CameraRight;
uniform vec3 u_CameraUp;
uniform mat4 u_MVP;
uniform mat4 u_MVP_inverse;
uniform vec2 u_Mouse;
uniform float u_Time;


in vec4 near_4;   
in vec4 far_4;
in vec2 v_TexCoord;
in vec3 origin;
in vec3 ray_dir;

const int NUMBER_OF_STEPS = 128;
const float MINIMUM_HIT_DISTANCE = 0.001;
const float MAXIMUM_TRACE_DISTANCE = 10000.0;

const vec3 LIGHT_POS = vec3(3.0, 3.0, 4.0);
const vec3 SPHERES[3] = vec3[](vec3(0.0, -1.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(1.0, -1.0, 1.0));
const vec3 LIGHT_COLOR = vec3(1.0, 0.0, 0.0);
const float LIGHT_INTENSITY = 20;
const vec3 SPHERE_POS = vec3(0.5, 0.5, 0.0);


vec3 applyFog( in vec3  rgb,       // original color of the pixel
               in float distance ) // camera to point distance
{
    const float b = 0.1;
    float fogAmount = 1.0 - exp( -distance*b );
    vec3  fogColor  = vec3(0.5,0.6,0.7);
    return mix( rgb, fogColor, fogAmount );
}

vec3 blinn_phong(vec3 currPos, vec3 viewDir, vec3 normal);
float distanceToClosest(vec3 currPos);

float distance_from_sphere(in vec3 p, in vec3 c, float r)
{
    return length(p - c) - r;
}

float distanceFromPlane(in vec3 p){
    return p.y + 1;
}

//Estimate normal 
const float EPS=0.001;
vec3 estimateNormal(vec3 p){
    float xPl=distanceToClosest(vec3(p.x+EPS,p.y,p.z));
    float xMi=distanceToClosest(vec3(p.x-EPS,p.y,p.z));
    float yPl=distanceToClosest(vec3(p.x,p.y+EPS,p.z));
    float yMi=distanceToClosest(vec3(p.x,p.y-EPS,p.z));
    float zPl=distanceToClosest(vec3(p.x,p.y,p.z+EPS));
    float zMi=distanceToClosest(vec3(p.x,p.y,p.z-EPS));
    float xDiff=xPl-xMi;
    float yDiff=yPl-yMi;
    float zDiff=zPl-zMi;
    return normalize(vec3(xDiff,yDiff,zDiff));
}

vec3 ray_march(in vec3 ro, in vec3 rd)
{
    float total_distance_traveled = 0.0;


 
    for (int i = 0; i < NUMBER_OF_STEPS; ++i)
    {
        vec3 current_position = ro + total_distance_traveled * rd;

        int index = 0;
        float distance_to_closest = distanceToClosest(current_position);

        if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
        {
            vec3 normal = estimateNormal(current_position);
            vec3 bp = blinn_phong(current_position, -rd, normal);
            vec3 updated = applyFog(bp, total_distance_traveled);
            return updated;
        }

        if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
        {
            break;
        }
        total_distance_traveled += distance_to_closest;
    }
    return vec3(0.0);
}

float distanceToClosest(vec3 currPos) {
    float minv = 10000.0;
    for(int i = 0; i < SPHERES.length; i++) {
        float d = distance_from_sphere(currPos,SPHERES[i], 0.5);
        if(d < minv) {
            minv = d;
        }
    }
    minv = min(minv, distanceFromPlane(currPos));
    return minv;
}

vec3 blinn_phong(vec3 currPos, vec3 dirToView, vec3 normal) {
    const float amb = 0.1;
    const float diff = 0.5;
    const float shininess = 3.0;
    float distanceToLight = length(LIGHT_POS - currPos);
    vec3 dirToLight = normalize(LIGHT_POS - currPos);
    float dist = distanceToLight * distanceToLight; 

    vec3 mat_color;

    vec3 checkerboard = vec3(0.0, 0.0, 0.0);
    if(mod(floor(currPos.x) + floor(currPos.z), 2) >= 1 ) checkerboard = vec3(1.0, 1.0, 1.0);

    mat_color = checkerboard;

    //ambient, diffuse, specular
    vec3 ambient = amb * LIGHT_COLOR * mat_color;
    vec3 diffuse = diff * LIGHT_COLOR * LIGHT_INTENSITY/dist * mat_color * max(dot(dirToLight, normal), 0.0);

    vec3 halfvec = normalize(dirToLight + dirToView);
    float spec = pow(max(dot(normal, halfvec), 0.0), shininess);
    vec3 specular = LIGHT_COLOR * LIGHT_INTENSITY/dist * spec;

    vec3 color = (ambient + diffuse + specular) * mat_color;

    vec3 colorGammaCorrected = pow(color, vec3(1.0 / 2.2));
    return colorGammaCorrected;
}

vec3 renderVolume(float distInVolume, vec3 colorInc){
    //absorb and scatter coeffs are a probability density function
    const float absorptionCoeff = 0.5;
    const vec3 scatteringCoeff = vec3(0.5, 1.0, 0.3);
    float Beer_Lambert = exp(-distInVolume * absorptionCoeff);
    vec3 color = mix(scatteringCoeff, colorInc, Beer_Lambert);

    return vec3(0.0);
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}


void main() {

    //vec2 screen_pos = (gl_FragCoord.xy) / u_Resolution.xy;
    //vec2 uv = 2*screen_pos - 1;
    //uv.x *= u_Aspect;
    vec2 fragCoord = gl_FragCoord.xy;

    vec2 mouse = u_Mouse/u_Resolution;

    // camera	
    vec3 ta = vec3( 0.25, -0.75, -0.75 );
    vec3 ro = ta + vec3( 4.5*cos(0.1*u_Time + 7.0*mouse.x), sin(mouse.y*(3.14/45)) + 3.2, 4.5*sin(0.1*u_Time + 7.0*mouse.x) );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    vec2 p = (2.0*fragCoord-u_Resolution.xy)/u_Resolution.y;

    // focal length
    const float fl = 2.5;
        
    // ray direction
    vec3 rd = ca * normalize( vec3(p,fl) );

    // ray differentials...
    vec2 px = (2.0*(fragCoord+vec2(1.0,0.0))-u_Resolution.xy)/u_Resolution.y;
    vec2 py = (2.0*(fragCoord+vec2(0.0,1.0))-u_Resolution.xy)/u_Resolution.y;
    vec3 rdx = ca * normalize( vec3(px,fl) );
    vec3 rdy = ca * normalize( vec3(py,fl) );
        

    vec3 shaded_color = ray_march(ro, rd);
    color = vec4(shaded_color, 1.0);
}
