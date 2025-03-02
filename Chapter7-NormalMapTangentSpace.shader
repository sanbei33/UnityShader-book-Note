// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Normal Map In Tangent Space" {                                                                              //�����߿ռ��¼��㰼͹ӳ��
	Properties{
		//�������ԣ���ʽΪ�� Name ("display name",PropertiyType) = DefaultValue
		//                   ���� (" ��ʾ������ "��   ����     ) =   Ĭ��ֵ
		_Color ("Color Tint",Color) = (1,1,1,1)     //��ɫ��Ĭ�ϰ�ɫ
		_MainTex ("Main Tex",2D) = "White" {}       //������Ĭ�ϰ�ɫ����
		_BumpMap ("Normal Map",2D) = "bump" {}      //��������������ͼ����Ĭ��ֵ"bump" ��Unity���õķ�������
		_BumpScale ("Bump Scale",Float) = 1.0       //���ư�͹�̶ȵ����ԣ�Ϊ0��÷���������Թ��ղ����κ�Ӱ��
		_Specular ("Specular",Color) = (1,1,1,1)    //���淴����ɫ
		_Gloss ("Gloss",Range(8.0,256)) = 20        //�����
		}
					//һϵ��SubShader��Բ�ͬ�Կ�
	SubShader{                         //����һϵ��Pass
		Pass{                         //��ǩ��״̬��Pass�л�Pass������
			Tags{ "LightMode"="ForwardBase" }         //��ǩ(Tags)��ֵ�ԣ���ϣ�������Լ���ʱ��Ⱦ�������    LightMode���ڶ����Pass��Unity�Ĺ�����ˮ���еĽ�ɫ

			CGPROGRAM
			
			#pragma vertex vert                 //���嶥����ɫ����ƬԪ��ɫ��Ϊvert��frag
			#pragma fragment frag
			#include "Lighting.cginc"           //Ϊʹ�� _LightColor0 ��Unity���õ�һЩ����

			//���������Ϊ�˺�Properties������е����Խ�����ϵ����cg�������������������������ƥ��ı���
			fixed4 _Color;             //��ɫ
			sampler2D _MainTex;       //������
			float4 _MainTex_ST;                                              //Ϊ�˵õ�����������ԣ�ƽ�̺�ƫ��ϵ������Ϊ _MainTex �� _BumpMap ������
			sampler2D _BumpMap;        //��������������ͼ��                  _MainTex_ST �� _BumpMap_ST ����
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;          //���ư�͹�̶ȵ�����
			float _Gloss;             //�����

			//ʹ��һ���ṹ��struct�����嶥����ɫ��������
			struct a2v{
				float4 vertex : POSITION;             //POSITION�������Unity,��ģ�Ϳռ�Ķ����������vertex����
				float3 normal : NORMAL;              //NORMAL�������Unity,��ģ�Ϳռ�ķ��߷������normal����                                  
				float4 tangent : TANGENT;           //���߷���
				float4 texcoord : TEXCOORD0;       //��������
			};

			//����ƬԪ��ɫ��������
			struct v2f{
				float4 pos : SV_POSITION;             //SV_POSITION��vertex����MVP�任��Ľ����ģ�Ϳռ䵽�ü��ռ䣩
				float4 uv : TEXCOORD0;               //�����������꣬����������_MainTex
				float3 lightDir : TEXCOORD1;        //ָ���Դ�ķ����ڶ�����ɫ���м��㲢��ֵ���ݸ�ƬԪ��ɫ��
				float3 viewDir : TEXCOORD2;        //ָ������ķ����ӽǷ��򣩣��ڶ�����ɫ���м��㲢��ֵ���ݸ�ƬԪ��ɫ�������ڸ߹�����Ч������Blinn-Phong
			};

			//���嶥����ɫ��
			v2f vert(a2v v) {                 //����һ��������ɫ������vert��������һ��a2f���͵ı���v������ֵ��v2f����
				v2f o;                       //����һ��v2f���͵ı���o�����ڴ洢�����Ķ������ݣ����ݵ�ƬԪ��ɫ�� 
				o.pos = UnityObjectToClipPos (v.vertex);           //v.vertex�Ǵ���Ķ������꣬mul��ˣ���MVP������˽��������� ��ģ�Ϳռ�ת�����ü��ռ䣬�洢�� o.pos ��


				//      �������������  *  �����������ϵ��   +   ƫ����
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;      //����������������ź�ƫ�ƣ��õ����������������洢�� o.uv.xy ��
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;     //ʹ���������������꣬��ͨ��ֻ��ʹ��ͬһ����������   

				TANGENT_SPACE_ROTATION;                   //�궨�壬�õ���ģ�Ϳռ�ת�������߿ռ�ı任����rotation

				//ģ�Ϳռ�Ĺ��շ�����ӽǷ��� ������ rotation ��ˣ�ת�������߿ռ�
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;             //����һ��4D������ .xyz ����ȡǰ��������
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;              //���մ��ݸ�ƬԪ��ɫ�����ڹ��ռ���

				return o;                     //������õ���o���ظ�ƬԪ��ɫ����������
											 //�ü��ռ��еĶ���λ�ã�pos�����������꣨uv�������շ���lightDir�����ӽǷ���viewDir��
			}

			//����ƬԪ��ɫ��
			fixed4 frag(v2f i) : SV_Target{           //����һ��ƬԪ��ɫ������frag��������һ��v2f�ı���i������fixed4���͵�ֵSV_Target����ƬԪ��ɫ��������ݸ�������Ⱦ����
				fixed3 tangentLightDir = normalize(i.lightDir);    //��ȡ�Ӷ�����ɫ���������Ĺ��շ���i.lightDir�����������һ��
				fixed3 tangentViewDir = normalize(i.viewDir);     //���ӽǷ����һ��

				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);    //����tex2D�Է�����ͼ_BumpMap���в�������v2f�ṹ���е�uv���ݵ�z��w����ȡ�������꣬����������xy,������ͼ����zw
				fixed3 tangentNormal;                //��������tangentNormal�����ڴ洢�ӷ�����ͼ�����ķ���

				tangentNormal = UnpackNormal(packedNormal);         //ʹ��UnpackNormal�������ӷ�����ͼ��ȡ����ѹ�����߽�ѹ�������ķ���
				tangentNormal.xy *= _BumpScale;         //ӳ��ط��߷���󣬳�_BumpScale(���ư�͹�̶�)������tangentNormal��xy����
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));      //���㷨�ߵ�z������dot�����������tangentNormal��������ĵ��
				 //���ڵ�λ������������ x^2 + y^2 + z^2 = 1                                          //dot((x,y),(x,y)) = x * x + y * y
				 //���� z^2 = 1 - (x^2 + y^2)						                           //saturate�������ǽ�����������[0,1]��Χ�ڡ�С��0�򷵻�0������1�򷵻�1����Χ�ڷ���ԭֵ
																							  //sqrt�ǿ�������

				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;             //��������_MainTex�и���i.uv��������øõ����ɫֵ���洢��albedo�С����������Ļ�����ɫ����ϣ�
																				   //tex2D���ص���һ��fixed4����(����RGBA�ĸ�����)

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;      //���㻷�����յ�Ӱ�졣UNITY_LIGHTMODEL_AMBIENT��һ��ȫ�ֱ�������ʾ���������ɫ
																			//��albedo�õ��������նԱ�����ɫ��Ӱ��

				fixed3 diffuse = _LightColor0.rgb * albedo * max (0, dot(tangentNormal, tangentLightDir));
				//������������յĹ��ס�                                 //dot������˷�������շ���ĵ�������ֵ��ʾ��������淨�ߵļн�
																		//max(0,...)ȷ��������ߴӱ��汳���������ʱ�����ظ�ֵ
																	   //Ȼ���_LightColor0.rgb(��Դ����ɫ)��albedo(������ɫ)

				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);        //���������halfDir�����ǹ��շ�����ӽǷ���ĺ�������ͨ�����ڼ���߹ⷴ��
				fixed3 Specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				//���㾵�淴��ĸ߹ⲿ�֡�                                       //���ȼ��㷨����������ĵ��������ʾ���淴���ǿ��
																				//ʹ��pow������ָ����_Gloss,������ȣ����Ƹ߹�����

				return fixed4(ambient + diffuse + Specular, 1.0);   //���շ�����ɫֵ��
																   //������ �����⡢������͸߹ⲿ�֡�alphaֵΪ1����ʾ��ȫ��͸��
			}

			ENDCG

		}
	}
	Fallback "Specular"                  //SubShader֮��
}
	