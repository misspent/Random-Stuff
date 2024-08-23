//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Multi-LUT shader, using a texture atlas with multiple LUTs
// by Otis / Infuse Project.
// Based on Marty's LUT shader 1.0 for ReShade 3.0
// Copyright © 2008-2016 Marty McFly
// This is only a MODIFICATION to allocate a custom lut size-name configuration, all credits go to the original authors.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifndef fLUT_TextureName
	#define fLUT_TextureName "COAR3_MULTI.png"
#endif
#ifndef fLUT_TileSizeXY
	#define fLUT_TileSizeXY 64
#endif
#ifndef fLUT_TileAmount
	#define fLUT_TileAmount 64
#endif
#ifndef fLUT_LutAmount
	#define fLUT_LutAmount 100
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int fLUT_LutSelector < 
	ui_type = "combo";
	ui_min= 0; ui_max=16;
	ui_items="COAR\0WOODEN\0UNDERSKY\0ELECTRIC\0SUNLIGHT\0DRY GRASS\0NEAR VILLAGE\0VIVID ORANGE\0SIBERIA\0HARDLIGHT\0BPRT\0ISLAND\0ALPINE\0COLD WATER\0HIMALAYA\0HOLY LAND\0BPRT V2\0ALP\0BLUESHADE\0WHERE\0BLUE BLOOD\0TOP ZONE\0DUST\0CRISP AIR\0DREAMLIKE\0ALIVE\0DARK BLUE\0GLIGHT\0DARK BLUE V2\0CLASSIC\0UNDERSKY V2\0SEAWOOD\0URBAN\0ROMB\0RUSTY GOLD\0GOLD RAYS\0SUMMER\0SULFUR\0OFF\0GREEN GEM\0BRACET\0CODEV\0COLDMETAL\0SUNSHINE\0BEFORESMOKE\0HOLYSMOKE\0COLOR FLOW\0BUUGY\0DARKB\0GRANDOLD\0AUTUMN PAINTER\0THE Z.O.N.E\0DRY LAND\0REALFACT\0LATE ZONE\0GOLDEN DAYS\0BODY BETA\0BUUGY V2\0SKY SHINE\0WRENCHED\0STEAM\0GOLDEN AGE\0COLD WARM\0WARM COLD\0UNDER COLD ICE\0HALF OF BAD\0MAD DRY\0SWAMP\0CITY CAT\0HELL\0DEEP LIGHT\0SELLER\0UNDER BRAIN\0TOP ZONE V2\0DRY GRASS V2\0BLUE SILVER\0THIS EVENING\0ATLAS WATER\0SILENT ZONE\0DON'T TRUST\0DON'T SACRE\0COLOR MAGIC\0SHOOM\0WARM GROUND\0COLD WIND\0HEART OF PSY\0DARK GREEN\0BONDER\0MOSS\0MEK\0OVER UNREAL\0WORN\0ROTTEN\0NOIR\0ELDEN SUN\0EDEN ANOMALY\0AUTUMN RAYS\0AFTER FALL\0NEXT VIS\0COAR V2\0";
	ui_label = "The LUT to use";
	ui_tooltip = "The colorgrading to use. 'COAR' is the neutral preset";
> = 0;

uniform float fLUT_AmountChroma <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Color Intensity";
	ui_tooltip = "Intensity of the chroma/colorgrading of the LUT.";
> = 1.00;

uniform float fLUT_AmountLuma <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Level Intensity";
	ui_tooltip = "Intensity of the levels/black&white of the LUT.";
> = 1.00;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"
texture texMultiLUT < source = fLUT_TextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmount; Format = RGBA8; };
sampler	SamplerMultiLUT { Texture = texMultiLUT; };

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_MultiLUT_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);
	float2 texelsize = 1.0 / fLUT_TileSizeXY;
	texelsize.x /= fLUT_TileAmount;

	float3 lutcoord = float3((color.xy*fLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_TileSizeXY-color.z);
	lutcoord.y /= fLUT_LutAmount;
	lutcoord.y += (float(fLUT_LutSelector)/ fLUT_LutAmount);
	float lerpfact = frac(lutcoord.z);
	lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

	float3 lutcolor = lerp(tex2D(SamplerMultiLUT, lutcoord.xy).xyz, tex2D(SamplerMultiLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

	color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

	res.xyz = color.xyz;
	res.w = 1.0;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


technique Colorgrading_LUT
{
	pass MultiLUT_Apply
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_MultiLUT_Apply;
	}
}