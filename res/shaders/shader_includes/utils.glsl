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
