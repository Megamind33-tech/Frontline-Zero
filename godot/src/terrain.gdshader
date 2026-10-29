shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D ground_texture : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world;
float grain(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float box_mask(vec2 p, vec2 center, vec2 halfsize) {
 vec2 d=abs(p-center)-halfsize;
 return 1.0-smoothstep(-0.35,0.35,max(d.x,d.y));
}
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world.xz;
 vec3 grass=texture(ground_texture,p*.22).rgb;
 float tiny=texture(ground_texture,p*.65).r;
 vec3 color=grass*1.05;
 float road_distance=abs(p.y-(32.5+sin(p.x*.07)*.65));
 float shoulder=1.0-smoothstep(3.6,4.25,road_distance);
 float asphalt=1.0-smoothstep(3.05,3.35,road_distance+sin(p.x*6.0)*.035);
 color=mix(color,vec3(.23,.205,.15)*(0.85+tiny*.3),shoulder);
 color=mix(color,vec3(.105,.115,.105)*(0.85+tiny*.3),asphalt);
 float paint=(1.0-smoothstep(.035,.075,road_distance))*step(mod(p.x,7.0),3.0);
 color=mix(color,vec3(.58,.55,.39),paint*.65);
 float trail=(1.0-smoothstep(.9,1.5,abs(p.x-50.0-sin(p.y*.55))))*step(12.,p.y)*step(p.y,53.);
 color=mix(color,vec3(.25,.22,.15)*(0.75+tiny*.4),trail*.8);
 float mud=box_mask(p,vec2(50.,32.5),vec2(6.,9.));
 vec3 wet=vec3(.12,.095,.06)*(0.8+tiny*.3);
 float rut=1.0-smoothstep(.08,.20,abs(mod(p.x-46.8,2.)-1.));
 color=mix(color,wet*(1.-rut*.35),mud);
 float woods=max(box_mask(p,vec2(50.,13.25),vec2(11.,5.75)),box_mask(p,vec2(50.,52.25),vec2(11.,5.75)));
 color*=1.0-woods*.18;
 ALBEDO=color;
 ROUGHNESS=mix(.96,.62,mud);
}
