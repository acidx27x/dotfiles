
local dragon_colors  = require("kanagawa.colors").setup({ theme = "dragon" })
local dragon_palette = dragon_colors.palette


require("kanagawa").setup({
  compile     = true,
  dimInactive = true,

  theme = "dragon",
  background = {
    dark  = "dragon",
    light = "lotus"
  },


  colors = {
    theme = {
      dragon = {
        ui = {
          pmenu = {
            fg = dragon_palette.oldWhite,
            bg = dragon_palette.dragonBlack0,
          },
          float = {
            fg_border = dragon_palette.waveBlue2,
            bg_border = dragon_palette.dragonBlack0,
          },
        },
        syn = {
          type       = dragon_palette.dragonOrange2,
          constant   = dragon_palette.carpYellow,
          parameter  = dragon_palette.waveAqua2,
          identifier = dragon_palette.sakuraPink,
          statement  = dragon_palette.dragonAqua,
          comment    = dragon_palette.fujiGray,
        },
        diag = {
          error   = dragon_palette.waveRed,
          warning = dragon_palette.surimiOrange,
        },
      },
    },
  },


  overrides = function(colors)
    local theme = colors.theme

    local is_dragon = theme.name == "dragon"
    local is_lotus  = theme.name == "lotus"
    local is_wave   = theme.name == "wave"

    return {
      -- default hl
      CursorLineNr = { fg = theme.ui.special, },

      WinBar   = { link = "StatusLine",   force = true, },
      WinBarNC = { link = "StatusLineNC", force = true, },

      EndOfBuffer = { link = "NonText", force = true, },

      DiagnosticError = { bold = true, italic = false, nocombine = true, },
      DiagnosticWarn  = { bold = true, italic = false, nocombine = true, },
      DiagnosticInfo  = { bold = true, italic = false, nocombine = true, },
      DiagnosticHint  = { bold = true, italic = false, nocombine = true, },
      DiagnosticOk    = { bold = true, italic = false, nocombine = true, },
      --

      -- plugin hl group
      NavicText = { link = "NonText", force = true, },

      BlinkCmpGhostText  = { fg = theme.ui.special, force = true, },
      BlinkCmpMenuBorder = { link = "FloatBorder",  force = true, },

      DapUIFloatBorder = { link = "FloatBorder",  force = true, },

      MiniIndentscopeSymbol = { link = "NonText", force = true, },

      MiniHipatternsFixme = { bold = true, italic = false, nocombine = true, },
      MiniHipatternsHack  = { bold = true, italic = false, nocombine = true, },
      MiniHipatternsNote  = { bold = true, italic = false, nocombine = true, },
      MiniHipatternsTodo  = { bold = true, italic = false, nocombine = true, },
      --
    }
  end,
})

