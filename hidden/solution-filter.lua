-- solution-filter.lua
-- control showing Div.answer via params.show_solution

local function has_class(el, class)
  for _, c in ipairs(el.classes or {}) do
    if c == class then return true end
  end
  return false
end

local function extract_show_solution(meta)
  local v = meta and meta.params and meta.params.show_solution
  if not v then return nil end
  local raw = pandoc.utils.stringify(v)
  if raw == "true" or raw == "1" or raw == "True" then return true end
  if raw == "false" or raw == "0" or raw == "False" then return false end
  return nil
end

function Pandoc(doc)
  local show_solution = extract_show_solution(doc.meta)

  if show_solution == nil and PANDOC_STATE then
    local state_meta = PANDOC_STATE.metadata or PANDOC_STATE.meta
    show_solution = extract_show_solution(state_meta)
  end

  if show_solution == nil then show_solution = false end

  local function handle_div(el)
    if has_class(el, "answer") then
      if not show_solution then
        return pandoc.Null()
      end

      local first = el.content[1]
      local label = pandoc.Strong({ pandoc.Str("Solution:"), pandoc.Space() })

      if first and first.t == "Para" then
        table.insert(first.content, 1, label)
      else
        table.insert(el.content, 1, pandoc.Para({ label }))
      end
      return el
    end
    return el
  end

  return doc:walk({ Div = handle_div })
end
