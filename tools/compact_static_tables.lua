-- Build-time serializer for immutable profession metadata. Equal nested values
-- share storage; no schema, numeric value or Lua array length is changed.
return function(value,encode)
    local nodes,bySignature={},{}
    local function keys(t)
        local out={} for k in pairs(t)do out[#out+1]=k end
        table.sort(out,function(a,b)if type(a)==type(b)then return a<b end return type(a)<type(b)end)
        return out
    end
    local function visit(t)
        local entries,signature={},{}
        for _,key in ipairs(keys(t))do
            local v=t[key]
            local child=type(v)=='table' and visit(v) or nil
            entries[#entries+1]={key=key,value=v,child=child}
            signature[#signature+1]=encode(key)..'='..(child and '@'..child.id or encode(v))..';'
        end
        local s=table.concat(signature)
        local node=bySignature[s]
        if node then node.count=node.count+1;return node end
        node={id=#nodes+1,count=1,entries=entries,value=t}
        nodes[#nodes+1]=node;bySignature[s]=node
        return node
    end
    local root=visit(value)
    local function shared(node)return node.count>1 and #node.entries>0 end
    local render
    render=function(node,definition)
        if shared(node)and not definition then return 'p['..node.id..']'end
        local n=0
        while rawget(node.value,n+1)~=nil do n=n+1 end
        for _,entry in ipairs(node.entries)do
            local k=entry.key
            if type(k)=='number'and k>n and k%1==0 then n=0;break end
        end
        local out={'{'}
        for _,entry in ipairs(node.entries)do
            local k=entry.key
            if not(type(k)=='number'and k>=1 and k<=n and k%1==0)then
                out[#out+1]='['..encode(k)..']='
            end
            out[#out+1]=entry.child and render(entry.child)or encode(entry.value)
            out[#out+1]=','
        end
        out[#out+1]='}'
        return table.concat(out)
    end
    local out={'do local p={}\n'}
    for _,node in ipairs(nodes)do
        if shared(node)then out[#out+1]='p['..node.id..']='..render(node,true)..'\n'end
    end
    out[#out+1]='LL.ItemDB.professionProfiles='..render(root)..'\nend\n'
    return table.concat(out)
end
