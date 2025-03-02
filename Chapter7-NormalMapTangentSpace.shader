// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Normal Map In Tangent Space" {                                                                              //在切线空间下计算凹凸映射
	Properties{
		//定义属性，格式为： Name ("display name",PropertiyType) = DefaultValue
		//                   名字 (" 显示的名称 "，   类型     ) =   默认值
		_Color ("Color Tint",Color) = (1,1,1,1)     //颜色，默认白色
		_MainTex ("Main Tex",2D) = "White" {}       //主纹理，默认白色纹理
		_BumpMap ("Normal Map",2D) = "bump" {}      //法线纹理（法线贴图），默认值"bump" 是Unity内置的法线纹理
		_BumpScale ("Bump Scale",Float) = 1.0       //控制凹凸程度的属性，为0则该法线纹理不会对光照产生任何影响
		_Specular ("Specular",Color) = (1,1,1,1)    //镜面反射颜色
		_Gloss ("Gloss",Range(8.0,256)) = 20        //光泽度
		}
					//一系列SubShader针对不同显卡
	SubShader{                         //定义一系列Pass
		Pass{                         //标签和状态在Pass中或Pass外声明
			Tags{ "LightMode"="ForwardBase" }         //标签(Tags)键值对：我希望怎样以及何时渲染这个对象    LightMode用于定义该Pass在Unity的光照流水线中的角色

			CGPROGRAM
			
			#pragma vertex vert                 //定义顶点着色器和片元着色器为vert和frag
			#pragma fragment frag
			#include "Lighting.cginc"           //为使用 _LightColor0 等Unity内置的一些变量

			//定义变量。为了和Properties语义块中的属性建立联系，在cg代码块中声明和上述属性类型匹配的变量
			fixed4 _Color;             //颜色
			sampler2D _MainTex;       //主纹理
			float4 _MainTex_ST;                                              //为了得到该纹理的属性（平铺和偏移系数），为 _MainTex 和 _BumpMap 定义了
			sampler2D _BumpMap;        //法线纹理（法线贴图）                  _MainTex_ST 和 _BumpMap_ST 变量
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;          //控制凹凸程度的属性
			float _Gloss;             //光泽度

			//使用一个结构体struct来定义顶点着色器的输入
			struct a2v{
				float4 vertex : POSITION;             //POSITION语义告诉Unity,用模型空间的顶点坐标填充vertex变量
				float3 normal : NORMAL;              //NORMAL语义告诉Unity,用模型空间的法线方向填充normal变量                                  
				float4 tangent : TANGENT;           //切线方向
				float4 texcoord : TEXCOORD0;       //纹理坐标
			};

			//定义片元着色器的输入
			struct v2f{
				float4 pos : SV_POSITION;             //SV_POSITION是vertex经过MVP变换后的结果（模型空间到裁剪空间）
				float4 uv : TEXCOORD0;               //接收纹理坐标，采样主纹理_MainTex
				float3 lightDir : TEXCOORD1;        //指向光源的方向，在顶点着色器中计算并插值传递给片元着色器
				float3 viewDir : TEXCOORD2;        //指向相机的方向（视角方向），在顶点着色器中计算并插值传递给片元着色器。用于高光计算等效果，如Blinn-Phong
			};

			//定义顶点着色器
			v2f vert(a2v v) {                 //定义一个顶点着色器函数vert，它接受一个a2f类型的变量v，返回值是v2f类型
				v2f o;                       //定义一个v2f类型的变量o，用于存储计算后的顶点数据，传递到片元着色器 
				o.pos = UnityObjectToClipPos (v.vertex);           //v.vertex是传入的顶点坐标，mul相乘，与MVP矩阵相乘将顶点坐标 从模型空间转换到裁剪空间，存储到 o.pos 里


				//      传入的纹理坐标  *  主纹理的缩放系数   +   偏移量
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;      //对纹理坐标进行缩放和偏移，得到调整后的纹理坐标存储到 o.uv.xy 中
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;     //使用了两张纹理坐标，但通常只会使用同一组纹理坐标   

				TANGENT_SPACE_ROTATION;                   //宏定义，得到从模型空间转换到切线空间的变换矩阵rotation

				//模型空间的光照方向和视角方向 经过和 rotation 相乘，转换到切线空间
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;             //返回一个4D向量， .xyz 来提取前三个分量
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;              //最终传递给片元着色器用于光照计算

				return o;                     //将计算得到的o返回给片元着色器，包含了
											 //裁剪空间中的顶点位置（pos）、纹理坐标（uv）、光照方向（lightDir）、视角方向（viewDir）
			}

			//定义片元着色器
			fixed4 frag(v2f i) : SV_Target{           //定义一个片元着色器函数frag，它接受一个v2f的变量i，返回fixed4类型的值SV_Target，将片元着色器结果传递给后续渲染步骤
				fixed3 tangentLightDir = normalize(i.lightDir);    //获取从顶点着色器传递来的光照方向（i.lightDir），并将其归一化
				fixed3 tangentViewDir = normalize(i.viewDir);     //将视角方向归一化

				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);    //利用tex2D对法线贴图_BumpMap进行采样，从v2f结构体中的uv数据的z和w分量取纹理坐标，主纹理坐标xy,法线贴图坐标zw
				fixed3 tangentNormal;                //声明变量tangentNormal，用于存储从法线贴图解包后的法线

				tangentNormal = UnpackNormal(packedNormal);         //使用UnpackNormal函数将从法线贴图获取到的压缩法线解压成真正的法线
				tangentNormal.xy *= _BumpScale;         //映射回法线方向后，乘_BumpScale(控制凹凸程度)来调整tangentNormal的xy分量
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));      //计算法线的z分量。dot函数计算的是tangentNormal和它自身的点积
				 //由于单位法线向量定义 x^2 + y^2 + z^2 = 1                                          //dot((x,y),(x,y)) = x * x + y * y
				 //所以 z^2 = 1 - (x^2 + y^2)						                           //saturate的作用是将输入限制在[0,1]范围内。小于0则返回0，大于1则返回1，范围内返回原值
																							  //sqrt是开方函数

				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;             //从主纹理_MainTex中根据i.uv采样，获得该点的颜色值，存储在albedo中。乘物体表面的基础颜色（混合）
																				   //tex2D返回的是一个fixed4类型(包含RGBA四个分量)

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;      //计算环境光照的影响。UNITY_LIGHTMODEL_AMBIENT是一个全局变量，表示环境光的颜色
																			//乘albedo得到环境光照对表面颜色的影响

				fixed3 diffuse = _LightColor0.rgb * albedo * max (0, dot(tangentNormal, tangentLightDir));
				//计算漫反射光照的贡献。                                 //dot里计算了法线与光照方向的点积，这个值表示光照与表面法线的夹角
																		//max(0,...)确保如果光线从表面背面照射过来时不返回负值
																	   //然后乘_LightColor0.rgb(光源的颜色)和albedo(表面颜色)

				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);        //计算半向量halfDir，它是光照方向和视角方向的和向量，通常用于计算高光反射
				fixed3 Specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				//计算镜面反射的高光部分。                                       //首先计算法线与半向量的点积，它表示镜面反射的强度
																				//使用pow函数，指数是_Gloss,即光泽度，控制高光的锐度

				return fixed4(ambient + diffuse + Specular, 1.0);   //最终返回颜色值。
																   //包含了 环境光、漫反射和高光部分。alpha值为1，表示完全不透明
			}

			ENDCG

		}
	}
	Fallback "Specular"                  //SubShader之外
}
	