shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 team_color : source_color = vec4(.72,.78,.54,1.);
uniform float tread_phase = 0.;
varying vec3 local_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.-2.*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { local_position=VERTEX; }
void fragment() {
 float n=noise(local_position.xz*1.8+local_position.y*.7);
 vec3 olive=vec3(.12,.16,.085);
 vec3 sand=vec3(.26,.245,.16);
 vec3 dark=vec3(.065,.08,.05);
 vec3 paint=mix(olive,sand,smoothstep(.54,.68,n));
 paint=mix(paint,dark,1.-smoothstep(.22,.32,n));
 vec3 base=COLOR.rgb;
 if (COLOR.r>.5) base=team_color.rgb;
 else if (COLOR.r>.15) base=paint;
 else if (COLOR.r<.05 && COLOR.g<.08) base*=.9+.1*sin(local_position.z*40.-tread_phase*6.);
 ALBEDO=base;
 METALLIC=(COLOR.r>.05 && COLOR.r<.15 && COLOR.g<.15) ? .6 : .12;
 ROUGHNESS=COLOR.g>COLOR.r*2. ? .25 : .82;
}
