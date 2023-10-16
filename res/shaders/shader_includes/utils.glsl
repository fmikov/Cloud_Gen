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

//ray box intersect by Sebastian Lague
vec2 intersect_box2( in vec3 ro, in vec3 rd, in vec3 boundsMin, in vec3 boundsMax ) 
{
    vec3 t0 = (boundsMin - ro) / rd;
	vec3 t1 = (boundsMax - ro) / rd;
	
	vec3 tmin = min(t0, t1);
	vec3 tmax = max(t0, t1);


	float dstA = max( max( tmin.x, tmin.y ), tmin.z );
	float dstB = min( tmax.x, min( tmax.y, tmax.z ) );
	
	float dstBox = max(0., dstA);
	float dstInsideBox = max(0., dstB - dstBox);

	return vec2( dstBox, dstInsideBox );
}
