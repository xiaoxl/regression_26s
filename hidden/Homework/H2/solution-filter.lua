-- solution-filter.lua
-- 根据 YAML 中 params.show_solution 控制是否显示 class="answer" 的解答块

-- 判断 div 是否包含某个 class
local function has_class(el, class)
  if not el.classes then return false end
  for _, c in ipairs(el.classes) do
    if c == class then return true end
  end
  return false
end

-- 从元数据中提取 show_solution（元数据可来自 doc.meta 或 PANDOC_STATE）
local function extract_show_solution(meta)
  if not meta or not meta.params or not meta.params.show_solution then
    return nil
  end
  local raw = pandoc.utils.stringify(meta.params.show_solution)
  if raw == "true" or raw == "1" or raw == "True" then
    return true
  elseif raw == "false" or raw == "0" or raw == "False" then
    return false
  else
    return nil
  end
end

function Pandoc(doc)
  -- 1. 最优先：从 doc.meta.params 拿参数
  local show_solution = extract_show_solution(doc.meta)

  -- 2. 如果 doc.meta 没有，再试 PANDOC_STATE
  if show_solution == nil and PANDOC_STATE then
    local state_meta = PANDOC_STATE.metadata or PANDOC_STATE.meta
    show_solution = extract_show_solution(state_meta)
  end

  -- 3. 默认值：false（学生版）
  if show_solution == nil then show_solution = false end

  -- 处理所有 Div
  local function handle_div(el)
    if has_class(el, "answer") then
      if show_solution then
        local first = el.content[1]

        if first and first.t == "Para" then
            table.insert(first.content, 1, pandoc.Strong("Solution: "))
            table.insert(first.content, 2, pandoc.Strong("")) -- ensures proper formatting
        else
            -- if first block is not Para, add a Para at top instead
            table.insert(el.content, 1, pandoc.Para({ pandoc.Str("Solution: ") }))
        end

        return el     -- 显示答案
      else
        return pandoc.Null()   -- 隐藏答案
      end
    end
    return el
  end

  return doc:walk({ Div = handle_div })
end
