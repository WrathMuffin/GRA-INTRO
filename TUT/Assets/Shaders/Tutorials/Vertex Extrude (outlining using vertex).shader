Shader "URP Vertex Extrude (outlining using vertex)"
{
    Properties
    {
        // needs a main textrure
        _MainTex ("Texture", 2D) = "white" {}

        _Amount ("Thickness", Range(-.1, .1)) = 0.001 // amount to extrude (imagine a thick film around the object, this amount basically increases/decreases how thick it is)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline"}

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag


            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // basically links the "variables" in the Properties block to the shader code
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float _Amount;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };


            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                // extrude along normal
                // gets the original position of the object in object space (ex: the pivot point of the object).
                // then adds the normal (the direction pointing out from the surface) multiplied by the amount we want to extrude
                float3 extrudedPosition = IN.positionOS.xyz + IN.normalOS * _Amount;

                // transform the extruded position from object space to homogeneous clip space
                // the pass it to the fragmanet shader
                OUT.positionHCS = TransformObjectToHClip(extrudedPosition);
                
                // pass the uv coordinates to the fragment shader
                OUT.uv = IN.uv;
                
                // make sure to transform the normal to world space for correct lighting
                // then normslize it to make sure it's a unit vector
                // and pass it to the fragment shader
                OUT.worldNormal = normalize(TransformObjectToWorldNormal(IN.normalOS));
                
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // use the texture in the property
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // gets the lighting direction and the color
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half3 lightColor = mainLight.color;

                // get diffuse lighting using lamberts cosine law
                half NdotL = max(dot(IN.worldNormal, lightDir), 0.0);

                // get the final color
                half3 finalColor = albedo.rgb * lightColor * NdotL;

                //shows the color
                return half4(finalColor, 1.0);
            }

           ENDHLSL
        }
    }
}
