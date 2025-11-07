Shader "URP_OutlineADV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
      _OutlineColor ("Outline Color", Color) = (0,0,0,1)
	  _Outline ("Outline Width", Range (-1, 1)) = .5
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" }
		Tags {"Queue"="Transparent" }
	
        Pass
        {	Name "Texture Color"
	
		    /* having stencil here to make sure outline only shows where object is not rendered
            Stencil
            {
                // ref 1 means we set the reference value to 1
                Ref 1

                // comp Equal means we only render where the stencil buffer is equal to the reference value
                // aka only render this shader where the object is not rendered (stencil value is 1)
                Comp Equal
            }*/

			HLSLPROGRAM

            #pragma vertex vertTex
            #pragma fragment fragTex
           
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // Declare texture and extrusion amount
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormalT : TEXCOORD1;
            };

            // Vertex Shader (handles extrusion)
            Varyings vertTex(Attributes IN)
            {
                Varyings OUT;

                // Transform object space to homogeneous clip space
                OUT.position = TransformObjectToHClip(IN.vertex);

                // Pass UV coordinates to fragment shader
                OUT.uv = IN.uv;

                // Calculate the world-space normal for lighting
                OUT.worldNormalT = normalize(TransformObjectToWorldNormal(IN.normal));

                return OUT;
            }

            // Fragment Shader (handles texture sampling and lighting)
            half4 fragTex(Varyings IN) : SV_Target
            {
                // Sample the texture
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // Get the main light direction and color
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half3 lightColor = mainLight.color;

                // Calculate diffuse lighting using Lambert's cosine law
                half NdotL = max(dot(IN.worldNormalT, lightDir), 0.0);
                // Calculate final color based on diffuse lighting and texture color
                half3 finalColortex = albedo.rgb * lightColor * NdotL;

                return half4(finalColortex, 1.0); // Output final color
            }

            ENDHLSL
        }

		 Pass
        {	
            Name "OutlineColor"
            Tags { "LightMode" = "UniversalForward" }
            Cull Front
		
		    // having stencil here to make sure outline only shows where object is not rendered
            Stencil
            {
                // ref 1 means we set the reference value to 1
                Ref 1

                // comp Equal means we only render where the stencil buffer is equal to the reference value
                // aka only render this shader where the object is not rendered (stencil value is 1)
                Comp Equal
            }
						
			HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
           
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float _Outline;
			half4 _OutlineColor;
			CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
				
            };

            // Vertex Shader (handles extrusion)
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Transform object space to homogeneous clip space
                OUT.positionCS = TransformObjectToHClip(IN.positionOS);

                float3 norm   = normalize(mul ((float3x3)UNITY_MATRIX_IT_MV, IN.normalOS));
				float2 offset = normalize(mul((float2x2)UNITY_MATRIX_P, norm.xy));

                // Pass UV coordinates to fragment shader
                OUT.positionCS.xy += offset * OUT.positionCS.z * _Outline;

           		return OUT;
            }

            // Fragment Shader ()
            half4 frag(Varyings IN) : SV_Target
            {
                 //Set the color of the outline.
			    half4 finalColor = _OutlineColor;

                return finalColor; // Output final color
            }

            ENDHLSL
        }
	
	}
}

