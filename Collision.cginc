#ifndef COLLISION_CGINC
#define COLLISION_CGINC

struct appdata {
	float4 vertex : POSITION;
	float4 tangent : TANGENT;
	float3 normal : NORMAL;
	float4 texcoord : TEXCOORD0;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
	fixed4 color : COLOR;
	uint vid : SV_VertexID;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

sampler2D _BlendshapeLookupMap;
int _MapSize;
float3 _CompressionFactor, _CompressionOffset;

float _BlendshapeEffectAmplitude;
float _GlobalThickness;

sampler2D _CameraDepthTexture;

// from StackOverflow
inline float DecodeFloatRGBAFixed(float4 enc) {
	uint ex = (uint) (enc.x * 255);
	uint ey = (uint) (enc.y * 255);
	uint ez = (uint) (enc.z * 255);
	uint ew = (uint) (enc.w * 255);
	uint v = (ex << 24) + (ey << 16) + (ez << 8) + ew;
	return ((float) v) / (256.0 * 256.0 * 256.0 * 256.0);
}

void vert (inout appdata v) {
	float4 xSample = tex2Dlod(_BlendshapeLookupMap, float4(floor(fmod(v.vid * 3, _MapSize)) / (float) _MapSize, floor((v.vid * 3) / (float) _MapSize) / (float) _MapSize, 0, 0));
	float4 ySample = tex2Dlod(_BlendshapeLookupMap, float4(floor(fmod(v.vid * 3 + 1, _MapSize)) / (float) _MapSize, floor((v.vid * 3 + 1) / (float) _MapSize) / (float) _MapSize, 0, 0));
	float4 zSample = tex2Dlod(_BlendshapeLookupMap, float4(floor(fmod(v.vid * 3 + 2, _MapSize)) / (float) _MapSize, floor((v.vid * 3 + 2) / (float) _MapSize) / (float) _MapSize, 0, 0));
	float3 moveTo = 2 * float3(DecodeFloatRGBAFixed(xSample), DecodeFloatRGBAFixed(ySample), DecodeFloatRGBAFixed(zSample)) * _CompressionFactor - _CompressionOffset;
	
	float4 clipPos = UnityObjectToClipPos(v.vertex);
	float4 projPos = ComputeScreenPos(clipPos);
	projPos.xy /= projPos.w;
	float sceneZ = Linear01Depth(tex2Dlod(_CameraDepthTexture, float4(projPos.xy, 0, 0)).r);
	float vertexDepth = -UnityObjectToViewPos(v.vertex).z * _ProjectionParams.w;
	
	// assume that all objects have some finite globally defined thickness as opposed to infinite width.
	if (vertexDepth - sceneZ < _GlobalThickness * _ProjectionParams.w) {
		v.vertex.xyz += _BlendshapeEffectAmplitude * moveTo * saturate(1 - smoothstep(0, _ProjectionParams.w, (sceneZ - vertexDepth)));
	}
}

#endif
