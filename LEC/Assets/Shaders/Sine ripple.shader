Shader "Unlit/Sine move"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _speed ("Speed", Range(0,100)) = 1
        _ScaleUVX ("Scale x", Range(1,10)) = 1
        _ScaleUVY ("Scale x", Range(1,10)) = 1
    }

    SubShader
    {
        Tags { "RenderType"="UniversalRenderPipeline" }

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
