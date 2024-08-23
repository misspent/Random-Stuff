//Surface Sharpen by Ioxa
//Version 1.0 for ReShade 3.0

//Settings
uniform int SharpRadius
<
	ui_type = "drag";
	ui_min = 1; ui_max = 4;
	ui_tooltip = "1 = 3x3 mask, 2 = 5x5 mask, 3 = 7x7 mask.";
> = 1;

uniform float SharpOffset
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Additional adjustment for the blur radius. Values less than 1.00 will reduce the radius limiting the sharpening to finer details.";
> = 1.00;

uniform float SharpEdge
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 10.00;
	ui_tooltip = "Adjusts the strength of edge detection";
> = 0.800;

uniform int CurveType
<
	ui_type = "combo";
	ui_items = "\Smoothstep\0Smootherstep\0Techni\0SinWave\0";
	ui_tooltip = "Type of curve applied to the detail channel";
> = 0;

uniform float CurveStrength
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 4.00;
	ui_tooltip = "Amount of curve applied to the detail channel. Higher values will increase sharpening";
> = 1.2;

uniform float Slope
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 3.00;
	ui_tooltip = "Adjusts the slope of the detail channel. Values above 1 increase the strength, values below 1 decrease it.";
> = 1.2;

uniform int DebugMode
<
	ui_type = "combo";
	ui_items = "\None\0EdgeChannel\0DetailChannel\0BlurChannel\0";
	ui_tooltip = "Helpful for adjusting settings";
> = 0;

#include "ReShade.fxh"

float normpdfE(in float3 x, in float y)
{
	x = abs(x);
	float v = dot(x,x);
	return saturate(1/pow(1+(pow(v/y,2.0)),0.5));
}

float f(float x,float c)
{
	return saturate(pow(max(0.0,x),c)/pow(0.5,c-1));
}

float3 f3(float3 x,float c,float p)
{
	return (pow(max(0.0,x),c)/pow(p,c-1.0));
}

float3 g(float3 x, float c, float p)
{
	return (c*pow(p,c-1.0))/pow(p,c-1.0)*(x-p)+p;
}

float3 SurfaceSharpFinal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	#define SurfaceSharpFinalSampler ReShade::BackBuffer
	
	float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	float3 diff = 0.0;
	float factor = 0.0;
	float Z = 0.0;
	float3 final_color = 0.0;
	float sigma = ((SharpEdge+0.00001) * 0.01);
	float3 color;
	
	if (SharpRadius == 1)
	{
		int sampleOffsetsX[25] = {  0.0, 	 1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,      1,     2,     2,     3,     0,     3,     3,     1,    -1, 3, 3, 2, 2, 3, 3 };
		int sampleOffsetsY[25] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2,     0,     3,     1,    -1,     3,     3, 2, -2, 3, -3, 3, -3};	
		float sampleWeights[5] = { 0.225806, 0.150538, 0.150538, 0.0430108, 0.0430108 };
		
		[loop]
		for(int i = 1; i < 5; ++i) {
			color = tex2D(SurfaceSharpFinalSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * SharpOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(SurfaceSharpFinalSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * SharpOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}
	
	if (SharpRadius == 2)
	{
		int sampleOffsetsX[13] = {  0.0, 	   1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,    1,     2,     2 };
		int sampleOffsetsY[13] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2};
		float sampleWeights[13] = { 0.1509985387665926499, 0.1132489040749444874, 0.1132489040749444874, 0.0273989284225933369, 0.0273989284225933369, 0.0452995616018920668, 0.0452995616018920668, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0043838285270187332, 0.0043838285270187332 };
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(SurfaceSharpFinalSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * SharpOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(SurfaceSharpFinalSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * SharpOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}

	if (SharpRadius == 3)
	{
		float sampleOffsetsX[13] = { 				  0.0, 			    1.3846153846, 			 			  0, 	 		  1.3846153846,     	   	 1.3846153846,     		    3.2307692308,     		  			  0,     		 3.2307692308,     		   3.2307692308,     		 1.3846153846,    		   1.3846153846,     		  3.2307692308,     		  3.2307692308 };
		float sampleOffsetsY[13] = {  				  0.0,   					   0, 	  		   1.3846153846, 	 		  1.3846153846,     		-1.3846153846,     					   0,     		   3.2307692308,     		 1.3846153846,    		  -1.3846153846,     		 3.2307692308,   		  -3.2307692308,     		  3.2307692308,    		     -3.2307692308 };
		float sampleWeights[13] = { 0.0957733978977875942, 0.1333986613666725565, 0.1333986613666725565, 0.0421828199486419528, 0.0421828199486419528, 0.0296441469844336464, 0.0296441469844336464, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0020831022264565991,  0.0020831022264565991 };
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(SurfaceSharpFinalSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * SharpOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(SurfaceSharpFinalSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * SharpOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}	
	
	if (SharpRadius == 4)
	{
		float sampleOffsetsX[25] = { 				  0.0, 			       1.4584295168, 			 		   0, 	 		  1.4584295168,     	   	 1.4584295168,     		    3.4039848067,     		  			  0,     		 3.4039848067,     		   3.4039848067,     		 1.4584295168,    		   1.4584295168,     		  3.4039848067,     		  3.4039848067,		5.3518057801,			 0.0,	5.3518057801,	5.3518057801,   5.3518057801,	5.3518057801,	   1.4584295168,	    1.4584295168,	3.4039848067,	3.4039848067, 5.3518057801, 5.3518057801};
		float sampleOffsetsY[25] = {  				  0.0,   					   0, 	  		   1.4584295168, 	 		  1.4584295168,     		-1.4584295168,     					   0,     		   3.4039848067,     		    1.4584295168,    		     -1.4584295168,     	  3.4039848067,   	   -3.4039848067,     		  3.4039848067,    		     -3.4039848067, 		     0.0,	5.3518057801,	   1.4584295168,	  -1.4584295168,	3.4039848067,  -3.4039848067,	5.3518057801,	-5.3518057801,	5.3518057801,  -5.3518057801, 5.3518057801, -5.3518057801};
		float sampleWeights[25] = {                           0.05299184990795840687999609498603,              0.09256069846035847440860469965371,           0.09256069846035847440860469965371,           0.02149960564023589832299078385165,           0.02149960564023589832299078385165,                 0.05392678246987847562647201766774,              0.05392678246987847562647201766774,             0.01252588384627371007425549277902,             0.01252588384627371007425549277902,          0.01252588384627371007425549277902,         0.01252588384627371007425549277902,             0.00729770438775005041467389567467,               0.00729770438775005041467389567467, 	0.02038530184304811960185734706054,	0.02038530184304811960185734706054,	0.00473501127359426108157733854484,	0.00473501127359426108157733854484,	0.00275866461027743062478492361799,	0.00275866461027743062478492361799,	0.00473501127359426108157733854484,	 0.00473501127359426108157733854484,	0.00275866461027743062478492361799,	0.00275866461027743062478492361799, 0.00104282525148620420024312363461, 0.00104282525148620420024312363461};

		[loop]
		for(int i = 1; i < 25; ++i) {
			color = tex2D(SurfaceSharpFinalSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * SharpOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(SurfaceSharpFinalSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * SharpOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}	
	
	color = final_color/Z;

	float3 detail = (orig.rgb - color.rgb)+0.5;
	
	detail = (g(detail,Slope,0.5));
	float3 x = detail;
	
	if(CurveType == 0)
	{
		x = x*x*(3.0-2.0*x);
	}
	
	if(CurveType == 1)
	{
		x = x*x*x*(x*(x*6.0 - 15.0) + 10.0);
	}
	
	if(CurveType == 2)
	{
		x = (x * (x * (x * (x * (x * (x * (1.6 * x - 7.2) + 10.8) - 4.2) - 3.6) + 2.7) - 1.8) + 2.7) * x * x;
	}
	
	if(CurveType == 3)
	{
		x = sin(3.1415927 * 0.5 * x);
		x *= x;
	}
	
	detail = lerp(detail,x,CurveStrength);
	
	if(DebugMode == 0)
	{
	color += (detail-0.5);
	}
	
	if(DebugMode == 1)
	{
	color = Z;
	}
	
	if(DebugMode == 2)
	{
	color = detail;
	}
	
	if(DebugMode == 3)
	{

	}
	
	return saturate(color);
}

technique SurfaceSharpen
{
	pass SurfaceSharpFinal
	{
		VertexShader = PostProcessVS;
		PixelShader = SurfaceSharpFinal;
	}

}