# cast.nvim

Plugin de Neovim (>= 0.10) que ejecuta el CLI [`cast`](https://github.com/Cerebellum-ITM/cast) en una ventana flotante. El proceso se mantiene vivo al ocultar la ventana y se reanuda al volver a abrirla.

## Requisitos

- Neovim `0.10+`
- Binario `cast` en el `PATH`

## Instalación

### lazy.nvim

```lua
{
  "Cerebellum-ITM/cast_vim_addon",
  opts = {},
}
```

### packer.nvim

```lua
use({
  "Cerebellum-ITM/cast_vim_addon",
  config = function() require("cast").setup() end,
})
```

## Uso

- `<leader>ct` — toggle (abre / oculta la ventana sin matar el proceso)
- `:CastToggle` / `:CastShow` / `:CastHide` / `:CastKill`
- Dentro de la ventana: `q` (modo normal) oculta; `<C-\><C-n>` sale a normal

## Configuración (valores por defecto)

```lua
require("cast").setup({
  cmd = "cast",
  args = {},
  keymap = "<leader>ct",
  border = "rounded",
  width = 0.8,       -- proporción de columnas
  height = 0.8,      -- proporción de filas
  title = " cast ",
  title_pos = "center",
  winblend = 0,
  start_insert = true,
  close_on_exit = false, -- si el proceso muere, mantener buffer para ver la salida
})
```
