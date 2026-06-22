return {
  -- Ensure snacks has the required features enabled
  {
    "folke/snacks.nvim",
    opts = {
      input = { enabled = true },
      picker = { enabled = true },
      terminal = { enabled = true },
    },
  },

  -- opencode.nvim
  {
    "NickvanDyke/opencode.nvim",
    lazy = false,
    config = function()
      vim.g.opencode_opts = {}
      vim.o.autoread = true

      vim.keymap.set({ "n", "x" }, "\\oa", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode" })
      vim.keymap.set({ "n", "x" }, "\\oo", function() require("opencode").select() end, { desc = "Opencode actions" })
      vim.keymap.set({ "n", "t" }, "\\ot", function() require("opencode").toggle() end, { desc = "Toggle opencode" })
    end,
  },
}
