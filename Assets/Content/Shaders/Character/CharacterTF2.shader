// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

///////////////////////////////////////////
// author     : chen yong
// create time: 2017/4/20
// modify time: 
// description: Reference http://www.valvesoftware.com/publications/2007/NPAR07_IllustrativeRenderingInTeamFortress2.pdf
///////////////////////////////////////////

Shader "Kingsoft/Character/CharacterTF2" {
    Properties {
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("MainTex", 2D) = "white" {}
		_ToonTex("ToonTex", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "white" {}
		_SpecMask("SpecularMask", 2D) = "white" {}
		_ExponentTex("ExponentTex", 2D) = "white" {}
		_RimExponent("RimExponent", Range(0, 10)) = 4
    }

    SubShader {
        Tags {
            "RenderType"="Opaque"
        }

        Pass {
            Name "ForwardBase"

            Tags {
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #define SHOULD_SAMPLE_SH_PROBE ( defined (LIGHTMAP_OFF) )
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
            #pragma exclude_renderers xbox360 ps3 flash d3d11_9x 
            #pragma target 3.0
            #pragma glsl
            
			half4 _LightColor0;
			half4 _Color;
            sampler2D _MainTex;
			sampler2D _ToonTex;
			sampler2D _BumpMap;
			sampler2D _SpecMask;
			sampler2D _ExponentTex;

			fixed _RimExponent;

			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 texcoord0 : TEXCOORD0;
			};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float3 tangentDir : TEXCOORD3;
				float3 binormalDir : TEXCOORD4;
				float3 globalAmbient : TEXCOORD5;
				LIGHTING_COORDS(6, 7)
			};

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = mul(unity_ObjectToWorld, float4(v.normal,0)).xyz;
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.binormalDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.globalAmbient = ShadeSH9(float4(o.normalDir, 1.0));

                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            fixed4 frag(VertexOutput i) : COLOR {
                float3x3 tangentTransform = float3x3( i.tangentDir, i.binormalDir, i.normalDir);
/////// Vectors:
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = normalize(i.normalDir);
								
				float3 normalTangent = UnpackNormal(tex2D(_BumpMap, i.uv0));
				normalDirection = normalize(i.tangentDir * normalTangent.x + i.binormalDir * normalTangent.y + i.normalDir * normalTangent.z);				

				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 lightReflectDirection = reflect(-lightDirection, normalDirection);
                
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
				float NdotL = dot(normalize(i.normalDir), lightDirection); // use original normal
				float NdotV = dot(normalDirection, viewDirection);

/////// View Independent Lighting Terms

				// Half Lambert
				NdotL = pow(NdotL*0.5 + 0.5, 1);

				// Diffuse Warping Function
				fixed3 ramp = tex2D(_ToonTex, half2(NdotL, NdotL)).rgb;

				// Directional Ambient Term
				fixed3 ambient = i.globalAmbient;

				fixed4 albedo = tex2D(_MainTex, i.uv0) * _Color;

				fixed3 _6a = albedo.rgb;
				fixed3 _6b = ramp;
				fixed3 _6c = ambient;
				fixed3 _6d = _6b*lightColor + _6c;
				fixed3 _6e = _6a * _6d;

///////	View Dependent Lighting Terms

				// Multiple Phong Terms
				fixed4 exponentTex = tex2D(_ExponentTex, i.uv0);				
				
				fixed kspec = lerp(1, 150, exponentTex.r); // specular exponent
				fixed ks = tex2D(_SpecMask, i.uv0).r; // specular mask
				fixed fs = lerp(0.3, 1, 1 - NdotV);
				fixed spec1 = pow(max(0, dot(viewDirection, lightReflectDirection)), kspec);

				fixed krim = _RimExponent; // rim exponent
				fixed kr = exponentTex.a; // rim mask
				fixed fr = pow(1 - max(0, dot(normalDirection, viewDirection)), 4);
				fixed spec2 = pow(max(0, dot(viewDirection, lightReflectDirection)), krim);

				fixed spec = max(fs*spec1, fr*kr*spec2);

				// Dedicated Rim Lighting
				fixed drim = fr*dot(normalDirection, fixed3(0, 1, 0));

				fixed3 _6f = spec*ks*lightColor;
				fixed3 _6g = drim*kr*0.5;
				fixed3 _6h = _6f + _6g;

				// Final result
				fixed3 _6j = _6e + _6h;

				return fixed4(_6j, 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
