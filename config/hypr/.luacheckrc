std = "lua51"
read_globals = {
  "hl", "Quickshell"
}
globals = {
  "dt"
}
ignore = {
  "111", -- setting non-standard global
  "112", -- mutating non-standard global
  "113", -- accessing undefined global
  "121", -- setting read-only global
  "122", -- mutating read-only global
  "131", -- unused global
  "211", -- unused variable
  "212", -- unused argument
  "631", -- line is too long
}
