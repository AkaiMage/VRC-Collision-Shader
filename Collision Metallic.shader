Shader "RedMage/Collision Metallic" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Emission ("Emission", 2D) = "black" {}
		[HDR] _EmissionColor ("Emission Color", Color) = (0,0,0,0)
		_Metallic ("Metallic", 2D) = "black" {}
		
		_Roughness ("Roughness", 2D) = "black" {}
		_Smoothness ("Smoothness", Range(0,1)) = 0.5
		_BumpMap ("Normal", 2D) = "bump" {}
		
		
		
		[HideInInspector] _CompressionFactor ("Compression Factor", Vector) = (1,1,1,0)
		[HideInInspector] _CompressionOffset ("Compression Offset", Vector) = (0,0,0,0)
		[HideInInspector] _BlendshapeLookupMap ("Blendshape Lookup Map", 2D) = "black" {}
		[HideInInspector] _MapSize ("Map Size", Int) = 16
		
		[Space]
		[Header(Collision Settings)]
		_BlendshapeEffectAmplitude ("Blendshape Effect Amplitude", Float) = 1
		_GlobalThickness ("Globally Assumed Collider Thickness", Float) = 1
	}
	SubShader {
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 200

		CGPROGRAM
		#include "Collision.cginc"
		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow nofog
		#pragma exclude_renderers xboxone ps4 n3ds wiiu gles gles3
		#pragma target 3.0
		
		struct Input {
			float2 uv_MainTex;
			float2 uv_Emission;
			float2 uv_BumpMap;
			float2 uv_Roughness;
			
			float2 uv_Metallic;
		};

		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _Emission;
		float4 _EmissionColor;
		sampler2D _Roughness;
		half _Smoothness;
		
		fixed4 _Color;
		
		sampler2D _Metallic;

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Emission = tex2D (_Emission, IN.uv_Emission) * _EmissionColor;
			o.Albedo = c.rgb;
			o.Smoothness = _Smoothness * tex2D (_Roughness, IN.uv_Roughness);
			o.Metallic = tex2D (_Metallic, IN.uv_Metallic);
			o.Alpha = c.a;
			o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));
		}
		
		ENDCG
	}
	FallBack "Diffuse"
}
