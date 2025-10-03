Shader "First shader multi UV"
// simple flat color shader
{
	Properties
	{
		_baseMap("Base map", 2D) = "white" {}
		_baseColor("Base color", color) = (1,1,1,1)

		// dropdown to pick UV set the base map will use
		[KeywordEnum(UV0, UV1)] _UVSET ("UV Set", Float) = 0
	}

	SubShader
	{
		Tags {"RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "UniversalRenderPipeline"}
		LOD 100

		Pass
		{
			Name "Unlit" // sample no lighting
			Tags {"Lightmode" = "UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			// create keywords that matches [KeywordEnum]
			#pragma shader_feature_local _UVSET_UV0_UVSET_UV1

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv0        : TEXCOORD0; // Mesh uv channel 0
				float2 uv1        : TEXCOORD1; // Mesh uv channel 1
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
				float2 uv          : TEXCOORD0; // UV chosen by dropdown
			};

			// texture & sampler
			TEXTURE2D(_baseMap);
			SAMPLER(sampler_baseMap);

			// material (SRP batcher)
			CBUFFER_START(UnityPerMaterial)
				float4 _baseColor;
				float4 _baseMap_ST; // tiling & offset
			CBUFFER_END

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

				// choose UV set based on dropdown
				#if defined(_UVSET_UV1)
				OUT.uv = TRANSFORM_TEX(IN.uv1, _baseMap);

				#else // UV is default
				OUT.uv = TRANSFORM_TEX(IN.uv0, _baseMap);
				#endif

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				half4 baseTex = SAMPLE_TEXTURE2D(_baseMap, sampler_baseMap, IN.uv);
				return half4(baseTex.rgb * _baseColor.rgb, 1.0);
			}

			ENDHLSL
		}
	}
	
	FallBack Off
}