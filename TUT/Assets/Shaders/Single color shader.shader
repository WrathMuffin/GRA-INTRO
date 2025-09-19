Shader "GRA INTRO - ShaderURP"
// simple flat color shader
{
	Properties
	{
		_myColor("Sample color", Color) = (1,1,1,1)
		//_mainTexture("Main texture", 2D) = "white" {}
	}

	SubShader
	{
		Tags {"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
		LOD 100

		Pass
		{
			Name "Unlit"
			Tags {"Lightmode" = "UniversalForward"}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct Attributes
			{
				float4 positionOS : POSITION;
				//float2 UV : TEXTCOORD0;
			};

			//TEXTURE2D(_mainTexture);
			//SAMPLER(_mainTexture);
			//CBUFFER

			float4 _myColor;

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
			//OUT.UV = IN.UV
				return OUT;
			};

			half4 frag(Varyings IN) : SV_Target
			{
				// take color form texture
				//SAMPLE_TEXTUE(_mainTexture, _sampler_mainTexture, IN.UV);

				return _myColor;
			}

			ENDHLSL
		}
	}
	
	FallBack Off
}