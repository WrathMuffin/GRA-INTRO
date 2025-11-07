Shader "Custom/URP_WaterShaderMod"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0, 1, 1, 1)  // Default is light blue
        _MainTex ("Water Texture", 2D) = "white" {}
        _Freq ("Wave Frequency", Range(0, 5)) = 3.0
        _Speed ("Wave Speed", Range(0, 10)) = 1.0
        _Amp ("Wave Amplitude", Range(0, 1)) = 0.1
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Include URP core functionality
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;  // Object space position
                float2 uv : TEXCOORD0;         // Texture coordinates
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // Homogeneous clip-space position
                float2 uv : TEXCOORD0;            // Pass UVs to fragment
            };

            // Declare properties for base color, texture, and wave parameters
            float4 _BaseColor;
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float _Freq;
            float _Speed;
            float _Amp;

            // Vertex Shader with wave animation
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Time-based animation for water waves
                float waveX = sin(_Time.x * _Speed + IN.positionOS.x * _Freq) * _Amp;
                float waveY = sin(_Time.y * _Speed + IN.positionOS.y * _Freq) * _Amp;

                // Adjust the vertex y position for wave effect
                float3 displacedPos = IN.positionOS.xyz;
                displacedPos.x += waveX;
                displacedPos.y += waveY;

                // Transform the displaced position to clip space
                OUT.positionHCS = TransformObjectToHClip(displacedPos);

                // Pass UV coordinates to the fragment shader
                OUT.uv = IN.uv;

                return OUT;
            }

            // Fragment Shader to apply texture and base color tint
            half4 frag(Varyings IN) : SV_Target
            {
                // Sample the texture and multiply by base color
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                return texColor * _BaseColor;
            }

            ENDHLSL
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float2 _ScaleUVX;
            float2 _ScaleUVY;
            float _speed;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = TransformObjectToHClip(v.vertex);

                o.uv = v.uv;

                // left right motion
                o.uv.x += sin(o.uv.y * _ScaleUVX + _Time.y) * _speed;

                // up down motion
                o.uv.y += sin(o.uv.x * _ScaleUVY + _Time.y) * _speed;

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
               half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
               return col;
            }

            ENDHLSL
        }
    }
}