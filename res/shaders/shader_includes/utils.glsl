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
