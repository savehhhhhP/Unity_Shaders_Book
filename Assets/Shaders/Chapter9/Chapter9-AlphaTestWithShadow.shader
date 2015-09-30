﻿Shader "Unity Shader Book/Chapter9-Alpha Test With Shadow" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
	}
	SubShader {
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			Cull Off
			
			CGPROGRAM
			
			#pragma multi_compile_fwdbase
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
				SHADOW_COORDS(3)
			};
			
			v2f vert(a2v v) {
			 	v2f o;
			 	// Transform the vertex from object space to projection space
			 	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			 	
			 	// Transform the normal fram object space to world space
			 	o.worldNormal = mul(v.normal, (float3x3)_World2Object);
			 	
			 	// Transform the vertex from object spacet to world space
			 	o.worldPos = mul(_Object2World, v.vertex).xyz;

			 	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			 	
			 	// Pass shadow coordinates to pixel shade
			 	TRANSFER_SHADOW(o);
			 	
			 	return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				
				fixed4 texColor = tex2D(_MainTex, i.uv);
				
				// Alpha test
  				clip (texColor.a - _Cutoff);
				
				// Use the texture to sample the diffuse color
				fixed3 diffuseColor = texColor.rgb * _Color.rgb;
				
				// Compute diffuse term
				fixed halfLambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
			 	fixed3 diffuse = _LightColor0.rgb * diffuseColor * halfLambert;
			 	
			 	// UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
			 	
				return fixed4(ambient + diffuse * atten, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Transparent/Cutout/VertexLit"
}
