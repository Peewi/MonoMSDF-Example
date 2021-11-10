#if OPENGL
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_5_0
#define PS_SHADERMODEL ps_5_0
#endif

// Mix of the enhanced shader from https://discourse.libcinder.org/t/cinder-sdftext-initial-release-wip/171/13 and the original msdf shader


matrix WorldViewProjection;
float2 TextureSize;
float PxRange;

texture GlyphTexture;
sampler glyphSampler = sampler_state
{
	Texture = (GlyphTexture);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	Mipfilter = LINEAR;
};

struct VertexShaderInput
{
	float4 Position : POSITION0;
	float4 Color : COLOR0;
	float4 StrokeColor : COLOR1;
	float2 TexCoord : TEXCOORD0;
};

struct VertexShaderOutput
{
	float4 Position : POSITION0;
	float4 Color : COLOR0;
	float4 StrokeColor : COLOR1;
	float2 TexCoord : TEXCOORD0;
};

VertexShaderOutput MainVS(in VertexShaderInput input)
{
	VertexShaderOutput output = (VertexShaderOutput)0;
	output.Position = mul(input.Position, WorldViewProjection);	
	output.Color = input.Color;
	output.StrokeColor = input.StrokeColor;
	output.TexCoord = input.TexCoord;

	return output;
}

float2 SafeNormalize(in float2 v)
{
	float len = length(v);
	len = (len > 0.0) ? 1.0 / len : 0.0;
	return v * len;
}

float Median(float a, float b, float c)
{	
	return max(min(a, b), min(max(a, b), c));
}

float4 MainPS(VertexShaderOutput input) : COLOR
{	
	// Convert normalized texture coordinates to absolute texture coordinates
	float2 uv = input.TexCoord * TextureSize;

	// Calculate derivatives
	float2 Jdx = ddx(uv);
	float2 Jdy = ddy(uv);

	// Sample texture
	float3 samp = tex2D(glyphSampler, input.TexCoord).rgb;

	// Calculate the signed distance (in texels)
	float sigDist = Median(samp.r, samp.g, samp.b) - 0.5f;

	// For proper anti-aliasing we need to calculate the signed distance in pixels.
	// We do this using the derivatives.	
	float2 gradDist = SafeNormalize(float2(ddx(sigDist), ddy(sigDist)));
	float2 grad = float2(gradDist.x * Jdx.x + gradDist.y * Jdy.x, gradDist.x * Jdx.y + gradDist.y * Jdy.y);

	// Apply anti-aliasing
	const float thickness = 0.125f;
	const float normalization = thickness * 0.5f * sqrt(2.0f);

	float afWidth = min(normalization * length(grad), 0.5f);
	float opacity = smoothstep(0.0f - afWidth, 0.0f + afWidth, sigDist);

	// Apply pre-multiplied alpha with gamma correction

	float4 color;
	color.a = pow(abs(input.Color.a * opacity), 1.0f / 2.2f);
	color.rgb = input.Color.rgb * color.a;

	return color;
}

float4 AltPS(VertexShaderOutput input) : COLOR
{	
	float2 msdfUnit = PxRange / TextureSize;
	float3 samp = tex2D(glyphSampler, input.TexCoord).rgb;

	float sigDist = Median(samp.r, samp.g, samp.b) - 0.5f;
	sigDist = sigDist * dot(msdfUnit, 0.5f / fwidth(input.TexCoord));

	float opacity = clamp(sigDist + 0.5f, 0.0f, 1.0f);
	return input.Color * opacity;
}

float4 StrokePS(VertexShaderOutput input) : COLOR
{
	float2 msdfUnit = PxRange / TextureSize;
	float3 samp = tex2D(glyphSampler, input.TexCoord).rgb;

	const float strokeThickness = 0.250f * 0.75f;
	float sigDist = Median(samp.r, samp.g, samp.b) - 0.25f - strokeThickness;
	sigDist = -(abs(sigDist) - strokeThickness);
	sigDist = sigDist * dot(msdfUnit, 0.5f / fwidth(input.TexCoord));

	float opacity = clamp(sigDist + 0.5f, 0.0f, 1.0f);
	//input.Color.rgb = float3(1.0f, 1.0f, 1.0f) - input.Color.rgb;
	return input.StrokeColor * opacity;
}

float4 SmallStrokePS(VertexShaderOutput input) : COLOR
{
	// Convert normalized texture coordinates to absolute texture coordinates
	float2 uv = input.TexCoord * TextureSize;

	// Calculate derivatives
	float2 Jdx = ddx(uv);
	float2 Jdy = ddy(uv);

	// Sample texture
	float3 samp = tex2D(glyphSampler, input.TexCoord).rgb;

	// Calculate the signed distance (in texels)
	const float strokeThickness = 0.250f * 0.75f;
	float sigDist = Median(samp.r, samp.g, samp.b) - 0.25f - strokeThickness;
	sigDist = -(abs(sigDist) - strokeThickness);

	// For proper anti-aliasing we need to calculate the signed distance in pixels.
	// We do this using the derivatives.	
	float2 gradDist = SafeNormalize(float2(ddx(sigDist), ddy(sigDist)));
	float2 grad = float2(gradDist.x * Jdx.x + gradDist.y * Jdy.x, gradDist.x * Jdx.y + gradDist.y * Jdy.y);

	// Apply anti-aliasing
	const float thickness = 0.125f;
	const float normalization = thickness * 0.5f * sqrt(2.0f);

	float afWidth = min(normalization * length(grad), 0.5f);
	float opacity = smoothstep(0.0f - afWidth, 0.0f + afWidth, sigDist);

	// Apply pre-multiplied alpha with gamma correction

	float4 color;
	color.a = pow(abs(input.StrokeColor.a * opacity), 1.0f / 2.2f);
	color.rgb = input.StrokeColor.rgb * color.a;

	return color;
}

float4 StrokedTextPS(VertexShaderOutput input) : COLOR
{
	float2 msdfUnit = PxRange / TextureSize;
	float3 samp = tex2D(glyphSampler, input.TexCoord).rgb;

	float sigDist = Median(samp.r, samp.g, samp.b) - 0.5f;
	sigDist = sigDist * dot(msdfUnit, 0.5f / fwidth(input.TexCoord));
	const float strokeThickness = 0.250f * 0.75f;
	float strokeDist = Median(samp.r, samp.g, samp.b) - 0.25f - strokeThickness;
	strokeDist = -(abs(strokeDist) - strokeThickness);
	strokeDist = strokeDist * dot(msdfUnit, 0.5f / fwidth(input.TexCoord));

	float opacity = clamp(sigDist + 0.5f, 0.0f, 1.0f);
	float strokeOpacity = clamp(strokeDist + 0.5f, 0.0f, 1.0f);
	return lerp(input.StrokeColor, input.Color, opacity) * max(opacity, strokeOpacity);
}

float4 SmallStrokedTextPS(VertexShaderOutput input) : COLOR
{
	float2 uv = input.TexCoord * TextureSize;
	float2 Jdx = ddx(uv);
	float2 Jdy = ddy(uv);
	float3 samp = tex2D(glyphSampler, input.TexCoord).rgb;

	// Calculate the signed distance (in texels)
	const float strokeThickness = 0.250f * 0.75f;
	float StrokeDist = Median(samp.r, samp.g, samp.b) - 0.25f - strokeThickness;
	StrokeDist = -(abs(StrokeDist) - strokeThickness);
	float sigDist = Median(samp.r, samp.g, samp.b) - 0.5f;

	// For proper anti-aliasing we need to calculate the signed distance in pixels.
	// We do this using the derivatives.
	float2 gradDist = SafeNormalize(float2(ddx(sigDist), ddy(sigDist)));
	float2 grad = float2(gradDist.x * Jdx.x + gradDist.y * Jdy.x, gradDist.x * Jdx.y + gradDist.y * Jdy.y);
	const float thickness = 0.125f;
	const float normalization = thickness * 0.5f * sqrt(2.0f);
	float afWidth = min(normalization * length(grad), 0.5f);
	float opacity = smoothstep(0.0f - afWidth, 0.0f + afWidth, sigDist);
	float strokeOpacity = smoothstep(0.0f - afWidth, 0.0f + afWidth, StrokeDist);
	
	return lerp(input.StrokeColor, input.Color, opacity) * max(opacity, strokeOpacity);
}

technique SmallText
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL MainVS();
		PixelShader = compile PS_SHADERMODEL MainPS();		
	}
};

technique LargeText
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL MainVS();		
		PixelShader = compile PS_SHADERMODEL AltPS();
	}
};

technique LargeStroke
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL MainVS();
		PixelShader = compile PS_SHADERMODEL StrokePS();
	}
};

technique SmallStroke
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL MainVS();
		PixelShader = compile PS_SHADERMODEL SmallStrokePS();
	}
};

technique LargeStrokedText
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL MainVS();
		PixelShader = compile PS_SHADERMODEL StrokedTextPS();
	}
};

technique SmallStrokedText
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL MainVS();
		PixelShader = compile PS_SHADERMODEL SmallStrokedTextPS();
	}
};
