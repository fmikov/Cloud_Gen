float rand(vec3 pos){
    return fract(sin(dot(pos, vec3(64.25375463, 23.27536534, 86.29678483))) * 59482.7542);
}

struct Ray
{
    vec3 ro;
    vec3 rd;
};

struct Sphere
{
    vec3 c;
    float r;
    int material;
};

struct Hit {
	float t0;
    float t1;
	int material_id;
	vec3 normal;
	vec3 origin;
    bool inside;
};

//------------------ from shadertoy, refactor later

//beer lambert function
float BeerLambert(float absorption, float dist)
{
    return exp(-absorption * dist);
}

//TODO check this
float GetLightAttenuation(float distanceToLight)
{
    return 1.0 / pow(distanceToLight, 2.0);
}

float Luminance(vec3 color)
{
    return (color.r * 0.3) + (color.g * 0.59) + (color.b * 0.11);
}

bool IsColorInsignificant(vec3 color)
{
    const float minValue = 0.009;
    return Luminance(color) < minValue;
}





//----------------------------------------------------------------


float smooth_min( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

//ray sphere intersect
bool intersect_sphere_test(
	Ray ray,
	Sphere sphere,
	in out Hit hit
){
	vec3 rc = sphere.c - ray.ro;
	float radius2 = sphere.r * sphere.r;
	float tca = dot(rc, ray.rd);
    //this line breaks intersection if we start the ray inside the sphere
    //if (tca < 0.) return false;

	float d2 = dot(rc, rc) - tca * tca;
	if (d2 > radius2)
		return false;

	float thc = sqrt(radius2 - d2);
	hit.t0 = tca - thc;
	hit.t1 = tca + thc;


    if (hit.t0 < 0) {
            if (hit.t1 < 0) return false;
            else {
                hit.inside = true;
                hit.t0 = 0;
            }
        }

    return true;
}


// ray-box intersection from iq
vec2 intersect_box( in vec3 ro, in vec3 rd, in vec3 cen, in vec3 rad ) 
{
    vec3 m = 1.0/rd;
    vec3 n = m*(ro-cen);
    vec3 k = abs(m)*rad;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
	if( tN > tF || tF < 0.0) return vec2(-1.0);

	return vec2( tN, tF );
}
