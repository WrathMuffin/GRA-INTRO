Shader "Alvaro/URP/PBR_MetalRough_Safe"
{
    Properties
    {
        _Color       ("Color", Color) = (1,1,1,1)
        _SpecColor   ("Specular (dielectric tint)", Color) = (1,1,1,1)
        _Smoothness  ("Smoothness", Range(0,1)) = 0.5
        _MainTex     ("Base Texture", 2D) = "white" {}
        _MetallicTex ("Metallic (R)", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            Name "UniversalForward"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex   vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // constants inside HLSLPROGRAM 
            #define AQ_PI      3.14159265
            #define AQ_INV_PI  0.318309886
            #define AQ_EPS     1e-5

            struct Attributes { float4 positionOS:POSITION; float3 normalOS:NORMAL; float2 uv:TEXCOORD0; };
            struct Varyings   { float4 positionHCS:SV_POSITION; float3 positionWS:TEXCOORD2; float3 normalWS:TEXCOORD1; float2 uv:TEXCOORD0; };

            TEXTURE2D(_MainTex);     SAMPLER(sampler_MainTex);
            TEXTURE2D(_MetallicTex); SAMPLER(sampler_MetallicTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _SpecColor;
                float  _Smoothness;
            CBUFFER_END

            Varyings vert(Attributes IN){
                Varyings OUT;
                float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionHCS = TransformWorldToHClip(posWS);
                OUT.positionWS  = posWS;
                OUT.normalWS    = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.uv          = IN.uv;
                return OUT;
            }

            // prefixed helpers to avoid collisions
            float AQ_D_GGX(float NdotH, float a){
                float a2 = a*a;
                float denom = (NdotH*NdotH)*(a2-1.0)+1.0;
                return a2 / (AQ_PI*denom*denom + AQ_EPS);
            }
            float AQ_V_SmithGGX(float NdotV, float NdotL, float a){
                float a2=a*a;
                float gv = NdotV*sqrt(a2 + (1.0-a2)*NdotL*NdotL);
                float gl = NdotL*sqrt(a2 + (1.0-a2)*NdotV*NdotV);
                return 0.5 / (gv+gl + AQ_EPS);
            }
            float3 AQ_F_Schlick(float3 F0, float VdotH){
                float f = pow(saturate(1.0-VdotH),5.0);
                return F0 + (1.0-F0)*f;
            }

            half4 frag(Varyings IN):SV_Target
            {
                float3 N = normalize(IN.normalWS);
                float3 V = normalize(GetWorldSpaceViewDir(IN.positionWS));

                float4 baseTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _Color;
                float3 albedo  = baseTex.rgb;
                float  metallic = saturate(SAMPLE_TEXTURE2D(_MetallicTex, sampler_MetallicTex, IN.uv).r);

                float smoothness = saturate(_Smoothness);
                float roughness  = saturate(1.0 - smoothness);
                float a          = max(0.001, roughness*roughness);

                float3 dielectricF0 = lerp(float3(0.04,0.04,0.04), _SpecColor.rgb, 0.5);
                float3 F0 = lerp(dielectricF0, albedo, metallic);

                Light mainLight = GetMainLight();             // URP helper, no shadows here
                float3 L = normalize(mainLight.direction);
                float3 H = normalize(L + V);

                float NdotL = saturate(dot(N,L));
                float NdotV = saturate(dot(N,V));
                float NdotH = saturate(dot(N,H));
                float VdotH = saturate(dot(V,H));

                float  D   = AQ_D_GGX(NdotH, a);
                float  Vis = AQ_V_SmithGGX(NdotV, NdotL, a);
                float3 F   = AQ_F_Schlick(F0, VdotH);
                float3 specBRDF = D * Vis * F;

                float3 diffuseColor = albedo * (1.0 - metallic);
                float3 diffuseBRDF  = diffuseColor * AQ_INV_PI;

                float3 radiance = mainLight.color * NdotL;
                float3 color    = (diffuseBRDF + specBRDF) * radiance;

                return half4(color, baseTex.a);
            }
            ENDHLSL
        }
    }
}