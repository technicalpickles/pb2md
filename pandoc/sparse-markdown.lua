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

function all_whitespace_children(elem)
  return false
  -- elem.content.filter(
  --   function(e)
  --     return true
  --   end
  -- )
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

-- function Span(elem)
--   return rebuild_without_noise(elem)
-- end

-- function Cite(elem)
--   return rebuild_without_noise(elem)
-- end

-- function Header(elem)
--   return rebuild_without_noise(elem)
-- end

function Link(elem)
  if elem.attr then
    if elem.attr.classes and #elem.attr.classes > 0 then
      elem.attr.classes = {}
    end

    if elem.attr.identifier and #elem.attr.identifier > 0 then
      elem.attr.identifier = nil
    end
  end
  return elem
end