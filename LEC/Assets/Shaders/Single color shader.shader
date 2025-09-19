Shader "Lec2 ShaderURP"
// simple flat color shader
{
	Properties
	{
		_myColor("Sample color", Color) = (0,1,1,1)
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
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
			};

			float4 _myColor;

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

				return OUT;
			};

			half4 frag(Varyings IN) : SV_Target
			{
				return _myColor;
			}

			ENDHLSL
		}
	}
	
	FallBack Off
}