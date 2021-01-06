-- require('mobdebug').start()

function no_children(elem)
  local has_children = false
  
  if not elem.content then
    return has_children
  end
  
  for index, child in ipairs(elem.content) do
    has_children = true
    break 
  end

  return has_children
  -- return false
  -- return not elem.content or elem.content == "" -- or next(elem) ~= nil
end

function isWhitespace(elem)
  if not elem then
    return true
  end

  return elem.t == 'Space' or elem.t == 'LineBreak' or (elem.t == 'String' and elem.text == '')
end

function rebuild_without_noise(elem)
  replacement = elem:clone()
  if replacement.attr then
    replacement.attr.classes = nil
    replacement.attr.identifier =  nil
    if replacement.attr.attributes then
      replacement.attr.attributes.style = nil
    end
  end
  -- replacement.attributes then
  --re lacement.attributes.style = nil
  --d
  return replacement
end

function nullify_or_rebuild(elem)
  if nullify(elem) then
    return pandoc.Null()
  else
    return rebuild_without_noise(elem)
  end
end

function nullify(elem)
  return no_children(elem) or all_whitespace_children(elem)
end

-- function Div(elem)
--  return elem.content
-- end



function declassify(elem)
  if elem.attr.classes and #elem.attr.classes > 0 then
    elem.attr.classes = {}
  end
  return elem
end

function deidentify(elem)
  if elem.attr.identifier and #elem.attr.identifier > 0 then
    elem.attr.identifier = ""
  end
  return elem
end

function dedir(elem)
  if elem.attr.dir and #elem.attr.dir > 0 and elem.attr.dir ~= "auto" then
    elem.attr.dir = "auto"
  end
  return elem
end

function destyleize(elem)
  if elem.attr.attributes then
    elem.attr.attributes.style = nil
  end
  return elem
end

function clean(elem)
  if elem.attr then
    declassify(elem)
    deidentify(elem)
    destyleize(elem)
  end
  return elem
end

function cleanList(elem)
  elem = clean(elem)

  -- some list items end up wrapped up in a Para, instead of being just Plain
  return replaceParaWithPlain(elem)
end

-- function OrderedList(elem)
--   return cleanList(elem)
-- end

-- function BulletList(elem)
--   return cleanList(elem)
-- end

function replaceParaWithPlain(elem)
  return pandoc.walk_block(elem, {
    Para = function(el)
      return pandoc.Plain(el.content)
    end
  })
end

function Inline(elem)
  return clean(elem)
end

function Block(elem)
  return clean(elem)
end

-- function Link(elem)
--   local whitespaceElems = elem.c:filter(isWhitespace)
--   -- if elem.

--   return Block(elem)
-- end