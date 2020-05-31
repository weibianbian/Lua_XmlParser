function XmlParser()
    local xmlParser={}
    
    Tag={
        ['=']=1,
        ['/']=2,
        ['<']=3,
        ['>']=4,
        ['NUM']=5,
        ['ID']=6,
        ['IDX']=7,
        ['LITERAL']=8,
        ['?']=9,
    }

    TokenType={
        xml_tt_U=1, --初始化时候设置为未知
        xml_tt_H=2, --头<?xxxxx?>
        xml_tt_B=3, --标签头<xxxxx>
        xml_tt_E=4, --标签尾</xxxxx>
        xml_tt_BE=5,--无对应标签<xxxxx/>
        xml_tt_T=6,--标签头，标签尾所夹的内容，不允许出现<>
        xml_tt_InnerText=7,--
    }
    function xmlParser:ReadCh()
        self.index=self.index+1
        local ch=string.sub(self.context,self.index,self.index)
        return ch
    end
        local elements={}
    function xmlParser:GetToken()
        local peek=''
        local state=0
        local token={}
        local element={}
        while true do
            peek=self:Scan()
            if peek==nil then return -1 end
            -- print(TagX[peek.tag],peek.lexeme,"state",state)
            if state==0 then
                if peek.tag==Tag['<'] then
                    state=1
                elseif peek.tag==Tag['ID'] then
                    token.lexeme=peek.lexeme
                    token.tokenType=TokenType.xml_tt_InnerText
                    return token
                else
                    return -1
                end
            elseif state==1 then
                if peek.tag==Tag['?'] then
                    state=2
                elseif peek.tag==Tag['/'] then
                    state=4
                elseif peek.tag==Tag['ID'] then
                    token.tag=peek.lexeme
                    element.tag=token.tag
                    state=5
                else
                    return -1
                end
            elseif state==2 then
                if peek.tag==Tag['?'] then
                    state=3
                end
            elseif state==3 then
                if peek.tag==Tag['>'] then
                    token.tokenType=TokenType.xml_tt_H
                    return token
                else
                    return -1
                end
            elseif state==4 then
                if peek.tag==Tag['ID'] then
                    state=7
                    token.tag=peek.lexeme
                else
                    return -1
                end
            elseif state==7 then
                if peek.tag==Tag['>'] then
                    token.tokenType=TokenType.xml_tt_E
                    return token
                else
                    return -1
                end
            elseif state==5 then
                if peek.tag==Tag['>'] then
                    token.tokenType=TokenType.xml_tt_B
                    token.element=element
                    return token
                elseif peek.tag==Tag['/'] then
                    state=6
                elseif peek.tag==Tag['ID'] then
                    element.attributes=element.attributes or {}
                   while true do
                        local att={}
                        if peek.tag==Tag['ID'] then
                            att.attName=peek.lexeme
                            peek=self:Scan()
                        else
                            break
                        end
                        if peek.tag==Tag['='] then
                            peek=self:Scan()
                        else
                            return -1
                        end
                        if peek.tag==Tag['LITERAL'] then
                            att.attValue=peek.lexeme
                            -- peek=Lexer.Scan()
                        else
                            return -1
                        end
                        element.attributes[att.attName]=element.attributes[att.attName] or {}
                        table.insert(element.attributes[att.attName],att.attValue)
                        -- print(element.attributes[att.attName][1])
                    end
                else
                    print("error")
                    return -1
                end
            elseif state==6 then
                if peek.tag==Tag['>'] then
                    token.tokenType=TokenType.xml_tt_BE
                    token.element=element
                    return token
                else
                    return -1
                end
            end
        end
    end
    function xmlParser:RollBack()
        index=index-1
    end
    local peek=' '
    local line=1
    function xmlParser:Scan()
        while true do
            if peek==' ' or peek=='\t' then
                peek=self:ReadCh()
            elseif peek=='\n' then
                line=line+1
                -- print(line,'line')
                peek=self:ReadCh()
            else
                break
            end
        end
        --是否是数字或者字母 后者下划线
        local re=string.match(peek,'[a-zA-Z_]')
        if re~=nil then
            local letter=''
            while re~=nil do
                letter=letter..re
                peek=self:ReadCh()
                re=string.match(peek,'[a-zA-Z_]')
            end
            -- print(letter)
            return {tag=Tag['ID'],lexeme=letter}
        end
        re=string.match(peek,'[<>=/]')
        if re~=nil then
            if re=='<' then
                peek=self:ReadCh()
                if peek=='!' then --注释开始
                    peek=self:ReadCh()
                    peek=self:ReadCh()
                    if peek=='-' then
                        local str=''
                        while true do
                            peek=self:ReadCh()
                            if peek=='-' then
                                peek=self:ReadCh()
                                if peek=='-' then
                                    peek=self:ReadCh()
                                    if peek=='>' then
                                        --是注释
                                        peek=self:ReadCh()
                                        break
                                    end
                                end
                            end
                        end
                    else
                        print('注释错误了')
                    end
                else
                    -- print(re)
                    return {tag=Tag['<'],lexeme=re}
                end
                -- peek=Lexer.ReadCh()
            elseif re=='>' then
                -- print(peek)
                peek=self:ReadCh()
                return {tag=Tag['>'],lexeme=re}
            elseif re=='=' then
                -- print(peek)
                peek=self:ReadCh()
                return {tag=Tag['='],lexeme=re}
            elseif re=='/' then
                peek=self:ReadCh()
                return {tag=Tag['/'],lexeme=re}
            end
            return {tag=""}
        end
        re=string.match(peek,'["]')
        if re~=nil then
            local str=""
            while true do
                peek=self:ReadCh()
                if peek~='"' then
                    str=str..peek
                else    
                    peek=self:ReadCh()
                    break
                end
            end
            return {tag=Tag['LITERAL'],lexeme=str}
        end
    end
    function xmlParser:ParserText(xmlText)
        local stack={}
        local token=-1
        local elements={}
        self.context=xmlText
        self.index=0
        while true do
            token=self:GetToken()
            if token==-1 then break end
            if token.tokenType==TokenType.xml_tt_B then
                elements[token.tag]=token.element
                stack[#stack+1]=token
                print("压入一个：：",token.tag)
            elseif token.tokenType==TokenType.xml_tt_BE then
                elements[token.tag]=token.element
            elseif token.tokenType==TokenType.xml_tt_InnerText then
                if #stack<=0 then 
                    print("格式不对") 
                else
                    local element=elements[stack[#stack].tag]
                    element.InnerText=token.lexeme
                end
            elseif token.tokenType==TokenType.xml_tt_E then
                if #stack>0 then
                    if token.tag==stack[#stack].tag then
                        stack[#stack]=nil
                        print("弹出一个：：",token.tag)
                    end
                else
                    print("缺少标签头")
                    break
                end
            end        
        end
        if #stack>0 then 
            print("格式不对") 
            return  
        end
       pt(elements)
    end
    function xmlParser:LoadFile(xmlFilename, base)
        -- if not base then
        --     base = system.ResourceDirectory
        -- end

        -- local path = system.pathForFile(xmlFilename, base)
        local path = xmlFilename
        local hFile, err = io.open(path, "r");

        if hFile and not err then
            local xmlText = hFile:read("*a"); -- read file content
            io.close(hFile);
            return self:ParserText(xmlText), nil;
        else
            print(err)
            return nil
        end
    end
    return xmlParser
end








-- Lexer.OpenFile("zqf92.xml")






function _printt(lua_table,limit,indent__,step__)
    step__ = step__ or 0
    indent__ = indent__ or 0
    local content__ = ""
    if limit~=nil then
        if step__ > limit then 
            return "..."
        end
    end
    if step__ > 8 then
        return content__.."..."
    end
    if lua_table ==nil then 
        return "nil"
    end
    if type(lua_table) == "userdata" or type(lua_table) == "lightuserdata" or type(lua_table) == "thread" then
        return tostring(lua_table)
    end

    if type(lua_table) == "string" or type(lua_table) == "number" then
        return "[No-Table]:"..lua_table
    end

    for k,v in pairs(lua_table) do
        if k~="_class_type" then
            local szSuffix = ""
            TypeV = type(v)
            if  TypeV == "table" then
                szSuffix = "{"
            end
            local szPrefix = string.rep("  ",indent__)
            if TypeV == "table"and v._fields then
                local kk,vv = next(v._fields) 
                if type(vv) == "table" then
                    content__ = content__.."\n\t"..kk.name.."={".._printt(vv._fields,5,indent__+1,step__+1).."}"
                else
                    content__=content__.."\n\t"..kk.name.."="..vv
                end
            else
                if type(k) == "table" then
                    if k.name then
                        if type(v)~="table"then
                            content__=content__.."\n"..k.name.." = "..v
                        else
                            content__ = content__.."\n"..k.name.." = list:"
                            local tmp="\n"
                            for ka,va in ipairs(v) do
                                tmp=tmp.."#"..ka.."-"..tostring(va)
                            end
                            content__=content__..tmp
                        end
                    end
                elseif type(k) == "function" then
                    content__=content__.."\n fun=function"
                else
                    formatting=szPrefix..tostring(k).." = "..szSuffix
                    if TypeV=="table" then
                        content__=content__.."\n"..formatting
                        content__=content__.._printt(v,limit,indent__+1,step__+1)
                        content__=content__.."\n"..szPrefix.."},"
                    else
                        local szValue = ""
                        if TypeV=="string"then
                            szValue = string.format("%q",v)
                        else
                            szValue = tostring(v)
                        end
                        content__=content__.."\n"..formatting..(szValue or "nil")..","
                    end
                end
            end
        end
    end
    return content__
end

function  pt( ... )
    local arg = {...}
    local has = false
    for _,v in pairs(arg) do
        if v and type(v) ==  "table" then
            has = true
            break
        end
    end
    if not has then 
        print(...)
    end
    local content__ = ""
    for _,v in pairs(arg) do
        if v == "table" then
            content__ = content__..tostring(v).."\n"
        else
            content__=content__.."=>>[T]:".._printt(v,limit),debug.traceback().."\n"
        end
        print(content__)
    end
end
local xml=XmlParser()
xml:LoadFile("zqf92.xml")
