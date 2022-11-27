Shader "Unlit/OutlineShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Thickness ("Outline Thickness", Range(0.0 ,0.2)) = 0.1
        //Fire Properties
        _NoiseTex("Noise Texture 1", 2D) = "white" {}
        _NoiseTex2("Noise Texture 2", 2D) = "white" {}

        _BrighterCol ("Bright color", Color) = (1,1,1,1)
        _MiddleCol ("Middle color", Color) = (.7,.7,.7,1)
        _DarkerCol("Darker Color", Color) = (.4,.4,.4,1)

        _MiddleSubVal ("Subtract from middle Color", Range(0.0, 0.7)) = 0.2
        _DarkerSubVal ("Subtract from darker color", Range(0.0, 0.8)) = 0.4
        _Speed ("Fire speed", Range(0.5, 10)) = 2

    }
    SubShader
    {
      
        Pass //OUTLINE PASS
        {
            Tags
            {
            //"Queue" = "Transparent"
            }

            Blend SrcAlpha OneMinusSrcAlpha //Achieve transparency
            Zwrite Off //deactive z-buffer

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct meshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 uv1 : TEXCOORD1; 
            };

            struct Interpolators
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Thickness; 

            //Animation Variables. 
            sampler2D _NoiseTex;
			sampler2D _NoiseTex2;

            float4 _BrighterCol;
			float4 _MiddleCol;
			float4 _DarkerCol;
            float _MiddleSubVal;
            float _DarkerSubVal;
            float _Speed;


            //outline function, passes 4D vector position of vertices and an outlien value (ie thickness)
            float4 outline(float4 vertexPos, float outlineVal)
            {
                //4D matrix which scales the vertex, adds the outlineVal to the scale of the matrix
                float4x4 size = float4x4
                (
                    1 + outlineVal, 0, 0, 0,
                    0, 1 + outlineVal, 0, 0,
                    0, 0, 1 + outlineVal, 0,
                    0, 0, 0, 1 + outlineVal
                );
                //Return miltiplication between the scale/size and position of the vertices
                return mul(size, vertexPos);
            }

            Interpolators vert (meshData v)
            {
                Interpolators o;
                //Fetch the output of the outline function, and put it in a 4D vector (vertexPos)
                float4 vertexEnlarge = outline(v.vertex, _Thickness);         
                o.vertex = UnityObjectToClipPos(vertexEnlarge); //From Object space to ClipSpace (-1 to 1)
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (Interpolators i) : SV_Target
            {
                // sample the texture
                float noiseValue = tex2D(_NoiseTex, i.uv - float2(0,_Time.x*_Speed)).x; //Make the noise texture move "upwards" at a user defined speed 
                float noiseValue2 = tex2D(_NoiseTex2, i.uv).x;
                
                //3 step(y,x) with both the noise textures where we decrease the x value with a user defined number. Meaning we get less of noiseValue2 
                // at each step.
                float first = step(noiseValue, noiseValue2);
                float second = step(noiseValue, noiseValue2-_MiddleSubVal);
                float third = step(noiseValue, noiseValue2- _DarkerSubVal);



                //The complete "firey" effect
                float4 fireCol = float4(
                    //Caluclate where it should place the darker color compared to the bright fire color. Only getting a "thin" line, since we do first-second = diff of 0.2 as default.
                    //Lerp eases the transition between the two colors.
                    lerp(_BrighterCol.rgb, _DarkerCol.rgb, first-second),
                    first //Outer color, alpha of the fire.
                    );

                    //where to place the middle color, same as before do second-third, which is a diff of 0.2 as default too.  
                    fireCol.rgb = lerp(fireCol.rgb, _MiddleCol.rgb, second - third);

                return fireCol;
            }
            ENDCG
        }

         Pass //TEXTURE PASS
        {
           
            Tags
            {
            //"Queue" = "Transparent +1" //+1 to make sure it is rendered last
            }
            
            Blend SrcAlpha OneMinusSrcAlpha
           
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct meshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            Interpolators vert (meshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (Interpolators i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
       
    }
}
