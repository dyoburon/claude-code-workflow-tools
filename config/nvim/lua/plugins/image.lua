return {
  {
    "3rd/image.nvim",
    ft = { "markdown", "vimwiki" },
    build = false,
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki" },
        },
      },
      max_width = 200,
      max_height = 40,
      max_height_window_percentage = 40,
      max_width_window_percentage = 40,
      scale_factor = 8,
      window_overlap_clear_enabled = true,
    },
  },
}
