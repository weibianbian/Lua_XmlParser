function XmlParser()
    local Tag={
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

    local TokenType={
        xml_tt_U=1, --初始化时候设置为未知
        xml_tt_H=2, --头<?xxxxx?>
        xml_tt_B=3, --标签头<xxxxx>
        xml_tt_E=4, --标签尾</xxxxx>
        xml_tt_BE=5,--无对应标签<xxxxx/>
        xml_tt_T=6,--标签头，标签尾所夹的内容，不允许出现<>
        xml_tt_InnerText=7,--
    }
    local xmlParser={}
    function xmlParser:ReadCh()
        self.index=self.index+1
        local ch=string.sub(self.context,self.index,self.index)
        return ch
    end
    function xmlParser:GetToken()
        local state=0
        local token={}
        local peekToken=nil
        while true do
            peekToken=self:Scan()
            if peekToken==nil then 
                return -1 
            end
            if state==0 then
                if peekToken.tag==Tag['<'] then
                    state=1
                elseif peekToken.tag==Tag['ID'] then
                    token.lexeme=peekToken.lexeme
                    token.tokenType=TokenType.xml_tt_InnerText
                    return token
                else
                    return -1
                end
            elseif state==1 then
                if peekToken.tag==Tag['?'] then
                    state=2
                elseif peekToken.tag==Tag['/'] then
                    state=4
                elseif peekToken.tag==Tag['ID'] then
                    token.tag=peekToken.lexeme
                    token.element=Element(token.tag)
                    state=5
                else
                    return -1
                end
            elseif state==2 then
                if peekToken.tag==Tag['?'] then
                    state=3
                end
            elseif state==3 then
                if peekToken.tag==Tag['>'] then
                    token.tokenType=TokenType.xml_tt_H
                    return token
                else
                    return -1
                end
            elseif state==4 then
                if peekToken.tag==Tag['ID'] then
                    state=7
                    token.tag=peekToken.lexeme
                else
                    return -1
                end
            elseif state==7 then
                if peekToken.tag==Tag['>'] then
                    token.tokenType=TokenType.xml_tt_E
                    return token
                else
                    return -1
                end
            elseif state==5 then
                if peekToken.tag==Tag['>'] then
                    token.tokenType=TokenType.xml_tt_B
                    return token
                elseif peekToken.tag==Tag['/'] then
                    state=6
                elseif peekToken.tag==Tag['ID'] then
                   while true do
                        local att={}
                        if peekToken.tag==Tag['ID'] then
                            att.attName=peekToken.lexeme
                            peekToken=self:Scan()
                        else
                            break
                        end
                        if peekToken.tag==Tag['='] then
                            peekToken=self:Scan()
                        else
                            return -1
                        end
                        if peekToken.tag==Tag['LITERAL'] then
                            att.attValue=peekToken.lexeme
                            -- peekToken=self:Scan()
                        else
                            return -1
                        end
                        token.element:AddAttribute(att.attName,att.attValue)
                    end
                else
                    print("error")
                    return -1
                end
            elseif state==6 then
                if peekToken.tag==Tag['>'] then
                    token.tokenType=TokenType.xml_tt_BE
                    -- token.element=Element(token.tag)
                    return token
                else
                    return -1
                end
            end
        end
    end
    function xmlParser:Scan()
        while true do
            if self.peek==' ' or self.peek=='\t' then
                self.peek=self:ReadCh()
            elseif self.peek=='\n' then
                self.line=self.line+1
                print(self.line,'line')
                self.peek=self:ReadCh()
            else
                break
            end
        end
        --是否是数字或者字母 后者下划线
        local re=string.match(self.peek,'[a-zA-Z_]')
        if re~=nil then
            local letter=''
            while re~=nil do
                letter=letter..re
                self.peek=self:ReadCh()
                re=string.match(self.peek,'[a-zA-Z_]')
            end
            -- print(letter)
            return {tag=Tag['ID'],lexeme=letter}
        end
        re=string.match(self.peek,'[<>=/]')
        if re~=nil then
            if re=='<' then
                self.peek=self:ReadCh()
                if self.peek=='!' then --注释开始
                    self.peek=self:ReadCh()
                    self.peek=self:ReadCh()
                    if self.peek=='-' then
                        local str=''
                        while true do
                            self.peek=self:ReadCh()
                            if self.peek=='-' then
                                self.peek=self:ReadCh()
                                if self.peek=='-' then
                                    self.peek=self:ReadCh()
                                    if self.peek=='>' then
                                        --是注释
                                        self.peek=self:ReadCh()
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
                -- self.peek=Lexer.ReadCh()
            elseif re=='>' then
                self.peek=self:ReadCh()
                return {tag=Tag['>'],lexeme=re}
            elseif re=='=' then
                self.peek=self:ReadCh()
                return {tag=Tag['='],lexeme=re}
            elseif re=='/' then
                self.peek=self:ReadCh()
                return {tag=Tag['/'],lexeme=re}
            end
            return {tag=""}
        end
        re=string.match(self.peek,'["]')
        if re~=nil then
            local str=""
            while true do
                self.peek=self:ReadCh()
                if self.peek~='"' then
                    str=str..self.peek
                else    
                    self.peek=self:ReadCh()
                    break
                end
            end
            return {tag=Tag['LITERAL'],lexeme=str}
        end
    end
    function xmlParser:ParserText(xmlText)
        local stack={}
        local token=-1
        local root=nil
        self.peek=' '
        self.context=xmlText
        self.index=0
        self.line=1
        while true do
            token=self:GetToken()
            if token==-1 then break end
            if token.tokenType==TokenType.xml_tt_B then
                if #stack==0 then
                    root=token.element
                else
                    local element=stack[#stack]
                    element:AddChild(token.element)
                end
                print("压入一个")
                stack[#stack+1]=token.element
            elseif token.tokenType==TokenType.xml_tt_BE then
                if #stack==0 then
                    pritn("error   token.tokenType==TokenType.xml_tt_BE")
                else
                    local element=stack[#stack]
                    element:AddChild(token.element)
                end
            elseif token.tokenType==TokenType.xml_tt_InnerText then
                if #stack<=0 then 
                    print("格式不对 token.tokenType==TokenType.xml_tt_InnerText") 
                else
                    local element=stack[#stack]
                    element.InnerText=token.lexeme
                end
            elseif token.tokenType==TokenType.xml_tt_E then
                if #stack>0 then
                    if token.tag==stack[#stack]:Name() then
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
       return root
    end
    function xmlParser:LoadFile(xmlFilename, base)
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


function Element(name)
    local element={}
    element.___innerText = nil
    element.___name = name
    element.___childrens = {}
    element.___attributes = {}
    function element:InnerText() return self.___innerText end
    function element:Name() return self.___name end
    function element:Childrens() return self.___childrens end
    function element:NumChildrens() return #self.___children end
    function element:AddChild(child)
        if self[child:Name()] ~= nil then
            table.insert(self[child:Name()], child)
        else
            self[child:Name()] = child
        end
        table.insert(self.___childrens, child)
    end
    function element:Attributes() return self.___attributes end
    function element:NumAttributes() return #self.___attributes end
    function element:AddAttribute(name, value)
        local lName = name
        if self[name] ~= nil then
            table.insert(self[name], value)
        else
            self[name] = value
        end
        table.insert(self.___attributes, { name = name, value = self[name] })
    end
    return element
end
