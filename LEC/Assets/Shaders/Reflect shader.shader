Shader "Reflective shader"
// reflector shader
{
	Properties
	{
		_baseMap("Base map", 2D) = "white" {}
		_baseColor("Base color", color) = (1,1,1,1)

		// Environment reflection
		_envCube		("Reflection cubemap", Cube) = "" {}
		_envIntensity	("Reflection intensity", Range(0, 2)) = 1.0
		_envBlend		("Reflection blend (0 -> Base, 1 -> Env)", Range(0, 1)) = 1.0
		_fresnelPow		("Fresnel power", Range(0.1, 8)) = 5.0 // optional rim bias
		_fresnelBoost	("Fresnel boost", Range(0, 2)) = 1.0
	}

	SubShader
	{
		Tags {"RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "UniversalPipeline"}
		LOD 200

		Pass
		{
			Name "Unlit" // sample no lighting
			Tags {"Lightmode" = "UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			// create keywords that matches [KeywordEnum]
			//#pragma shader_feature_local _UVSET_UV0 UVSET_UV1

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS	  : NORMAL;
				float2 uv0        : TEXCOORD0; // Mesh uv channel 0
				//float2 uv1        : TEXCOORD1; // Mesh uv channel 1
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
				float3 positionWS  : TEXCOORD0;
				float3 normalWS    : TEXCOORD1;
				float2 uv          : TEXCOORD2; // UV chosen by dropdown
			};

			// texture & sampler
			TEXTURE2D(_baseMap);
			SAMPLER(sampler_baseMap);
			
			TEXTURECUBE(_envCube);
			SAMPLER(sampler_envCube);

			// material (SRP batcher)
			CBUFFER_START(UnityPerMaterial)
				float4 _baseColor;
				float4 _baseMap_ST; // tiling & offset

				float _envIntensity;
				float _envBlend	;
				float _fresnelPow;
				float _fresnelBoost;
			CBUFFER_END

			// vertex
			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
				float3 nrmWS = TransformObjectToWorldNormal(IN.normalOS);

				OUT.positionWS	= posWS;
				OUT.normalWS	= nrmWS;
				OUT.positionHCS = TransformObjectToHClip(posWS);

				// choose UV set based on dropdown
				//#if defined(_UVSET_UV1)
				//OUT.uv = TRANSFORM_TEX(IN.uv1, _baseMap);

				//#else // UV is default
				OUT.uv = TRANSFORM_TEX(IN.uv0, _baseMap);
				//#endif

				return OUT;
			}

			// fragment
			half4 frag(Varyings IN) : SV_Target
			{
				// base layer (optional)
				half3 baseCol = SAMPLE_TEXTURE2D(_baseMap, sampler_baseMap, IN.uv).rgb * _baseColor.rgb;

				// view dir (Wordls Space)
				float3 V = SafeNormalize(GetWorldSpaceViewDir(IN.positionWS));

				// normal (ws)
				float3 N = SafeNormalize(IN.normalWS);

				// reflection vect (WS) = reflect(incident, normal)
				// HLSL reflect() expects indident vector (surface to eye) = -V
				float3 R = reflect(-V, N);

				// Sample the cubemap with reflect vector
				half3 envCol = SAMPLE_TEXTURECUBE(_envCube, sampler_envCube, R).rgb * _envIntensity;

				// optional fresnel bias (stronger reflection at grazing angles)
				float ndotv = saturate(dot(N, V));
				float fresnel = pow(1.0 - ndotv, _fresnelPow) * _fresnelBoost;
				envCol *= (1.0 + fresnel);

				//half4 baseTex = SAMPLE_TEXTURE2D(_baseMap, sampler_baseMap, IN.uv);
				//return half4(baseTex.rgb * _baseColor.rgb, 1.0);
				
				// blend env over base (unlit)
				half3 finalCol = lerp(baseCol, envCol, _envBlend);
				return half4(finalCol, 1.0);
			}

			ENDHLSL
		}
	}
	
	FallBack Off
}