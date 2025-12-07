-------------------------------------------
-- solution-filter.lua  (class = "answer")
-- 根据 params.show_solution 控制是否显示答案块
-- 只实现 Pandoc(doc)，在里面用 doc:walk 处理所有 Div
-------------------------------------------

-- 打开日志文件
local log = io.open("solution-filter.log", "w")

local function LOG(msg)
  if log then
    log:write(msg .. "\n")
    log:flush()
  end
end

LOG("=== FILTER START ===")
LOG("Time: " .. os.date("%Y-%m-%d %H:%M:%S"))

-- 统计用
local div_count = 0
local answer_count = 0

-- 工具：判断 Div 是否带某个 class
local function has_class(el, class)
  if not el.classes then return false end
  for _, c in ipairs(el.classes) do
    if c == class then
      return true
    end
  end
  return false
end

------------------------------------------------
-- 核心入口：Pandoc(doc)
------------------------------------------------
function Pandoc(doc)
  LOG("---- Pandoc(doc) called ----")

  ------------------------------------------------
  -- 1. 从 doc.meta.params.show_solution 读取参数
  ------------------------------------------------
  local show_solution = false

  if doc.meta and doc.meta.params and doc.meta.params.show_solution then
    local raw = pandoc.utils.stringify(doc.meta.params.show_solution)
    LOG("meta.params.show_solution (raw) = " .. tostring(raw))

    if raw == "true" or raw == "1" or raw == "True" then
      show_solution = true
    else
      show_solution = false
    end
  else
    LOG("meta.params.show_solution not found; default = false")
  end

  LOG("Parsed show_solution = " .. tostring(show_solution))

  ------------------------------------------------
  -- 2. 定义处理 Div 的函数（闭包捕获 show_solution）
  ------------------------------------------------
  local function handle_div(el)
    div_count = div_count + 1

    local id = el.identifier or ""
    local cls = ""
    if el.classes and #el.classes > 0 then
      cls = table.concat(el.classes, ", ")
    end
    LOG(("Div #%d: id='%s', classes=[%s]"):format(div_count, id, cls))

    if has_class(el, "answer") then
      answer_count = answer_count + 1
      LOG(("  ==> Answer block #%d found; show_solution = %s")
            :format(answer_count, tostring(show_solution)))

      if show_solution then
        LOG("      KEEP answer block")
        return el
      else
        LOG("      REMOVE answer block")
        return pandoc.Null()
      end
    end

    return el
  end

  ------------------------------------------------
  -- 3. 用 doc:walk 走一遍 AST，只在 Div 上应用 handle_div
  ------------------------------------------------
  local new_doc = doc:walk({ Div = handle_div })

  ------------------------------------------------
  -- 4. 收尾日志
  ------------------------------------------------
  LOG("")
  LOG("=== FILTER COMPLETE ===")
  LOG("Total Div processed: " .. div_count)
  LOG("Total answer blocks: " .. answer_count)
  LOG("========================")

  if log then log:close() end

  return new_doc
end
