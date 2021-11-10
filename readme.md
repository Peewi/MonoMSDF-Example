# Example

This is an example of my [text renderer for Monogame](https://github.com/Peewi/MSDF) being used in a separate project.

![Sample](textrenderexample.png "Sample")

# Files
## FontExtension.dll
FontExtension.dll contains the content importer, content processor, text renderer and other classes used by these. It is referenced in both the .csproj and .mgcb files.

## FieldFontEffect.fx
FieldFontEffect.fx is the shader used to render the text. Add it to your content prject and load it with the content loader just like any other shader.

## msdf-atlas-gen.exe
msdf-atlas-gen.exe is used to generate the font atlas and layout information. It is available from the [msdf-atlas-gen releases page](https://github.com/Chlumsky/msdf-atlas-gen/releases). The path to msdf-atlas-gen.exe is set as a processor parameter for your font files. Or you can place it in your content folder and use the default path.

## Font files
Fonts are specified with json files and should be added to the content project (mgcb file). Here is an example file:
```
{
	"path":"C:\\Windows\\Fonts\\arial.ttf",
	"ranges":[
		{
			"start":32,
			"end":"0xFF"
		},
		{
			"start":"←",
			"end":"↙"
		}
	]
}
```

"path" points to a font file and can be either absolute or relative.

"ranges" controls which characters are included in the font atlas, similar to Monogame's spritefonts. Any number of ranges can be added. The "start" and "end" values can be a single character, a character's unicode number or a character's hexadecimal number. Both "start" and "end" are inclusive.