Shader "RedMage/Collision" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Emission ("Emission", 2D) = "black" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_CompressionFactor ("Compression Factor", Vector) = (1,1,1,0)
		_CompressionOffset ("Compression Offset", Vector) = (0,0,0,0)
		_BlendshapeLookupMap ("Blendshape Lookup Map", 2D) = "black" {}
		_MapSize ("Map Size", Int) = 16
		_Interpolator1 ("Interpolator1", Float) = 1
		_Interpolator2 ("Interpolator2", Float) = 1
	}
	SubShader {
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 200

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow nofog
		#pragma exclude_renderers xboxone ps4 n3ds wiiu gles gles3
		#pragma target 3.0
		
		struct Input {
			float2 uv_MainTex;
			float2 uv_Emission;
			
			float4 screenPos;
		};
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

		sampler2D _MainTex;
		sampler2D _Emission;
		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		
		float _Interpolator1;
		float _Interpolator2;
		
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
			float sceneZ = LinearEyeDepth(tex2Dlod(_CameraDepthTexture, float4(projPos.xy, 0, 0)).r) * _ProjectionParams.w;
			float vertexDepth = -UnityObjectToViewPos(v.vertex).z * _ProjectionParams.w;
			v.vertex.xyz += moveTo * saturate(_Interpolator1 * (1 - _Interpolator2 * smoothstep(0, _ProjectionParams.w, (sceneZ - vertexDepth))));
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Emission = tex2D (_Emission, IN.uv_Emission);
			o.Albedo = c.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		
		ENDCG
	}
	FallBack "Diffuse"
}
