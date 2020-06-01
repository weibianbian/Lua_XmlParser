# Lua_XmlParser

1.  Copy the LuaXmlParser.lua file to your project.
2.  Create a local variable `local xmlParser = require("LuaXmlParser.lua").XmlParser()`
3.  Read xml using `local root=xmlParser:ParserText(xmlString)` or `xmlParser:LoadFile(xmlFilename)`

# Parsing XML

``` xml
<root>
	<component size="1334,750" opaque="false">
	  <xiaoxixi>hi</xiaoxixi>
	  <displayList>
	    <image id="n10" name="bg" src="me2f1c" pkg="0tyncec1" xy="587,360" pivot="0.5,0.5" size="160,29">
	      <relation target="n3" sidePair="width-width,height-height"/>
	    </image>
	    <text id="n3" name="title" xy="604,362" pivot="0.5,0.5" size="125,24" fontSize="20" color="#ffffff" align="center" vAlign="middle" singleLine="true" text="标题文字标题"/>
	  </displayList>
	</component>
</root>
```

Using the simple method:

``` lua
root.component["size"] == "1334,750"
root.component.xiaoxixi:InnerText() == "hi"
root.component.displayList.image["id"]== "n10"
```

# Final notes

QQ:289417133