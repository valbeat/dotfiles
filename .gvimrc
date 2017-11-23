syntax enable

colorscheme hybrid

set cmdheight=1     " MacVim $VIM/gvimrc overwrites my .vimrc settings
set guioptions=c    " show no GUI components
set transparency=6 

set showtabline=2   "常にタブを表示
set guifont=Cica Regular:h16

if has('multi_byte_ime')
  highlight Cursor guifg=NONE guibg=Green
  highlight CursorIM guifg=NONE guibg=Purple
endif
