---@class blink.cmp.Source

---@class blink.cmp.CompletionItem
---@field label string
---@field kind? integer
---@field documentation? {kind: string, value: string}
---@field filterText? string

---@class blink.cmp.Context
---@field line string
---@field cursor integer[]

---@class blink.cmp.CompletionResponse
---@field is_incomplete_forward? boolean
---@field is_incomplete_backward? boolean
---@field items blink.cmp.CompletionItem[]
