local system = require 'pandoc.system'

function CodeBlock(el)
  if el.classes:includes('include') then
    local path = el.text:gsub("%s+", "")
    local f = io.open(path, "r")
    if f then
      local content = f:read("*all")
      f:close()
      el.text = content
      -- Rimuove la classe include per lasciare solo il linguaggio (es. bash)
      for i, class in ipairs(el.classes) do
        if class == 'include' then
          table.remove(el.classes, i)
          break
        end
      end
      return el
    else
      io.stderr:write("Filtro: Impossibile aprire il file " .. path .. "\n")
    end
  end
end

return {{ CodeBlock = CodeBlock }}
