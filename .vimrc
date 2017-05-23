if &compatible
  set nocompatible
endif

"----------------------------------------------
" dein.vim 設定
"----------------------------------------------
let g:rc_dir = expand('~/.vim')
let s:dein_dir = expand('~/.vim/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" dein.vim がなければ github から落としてくる
if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
      execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
    endif
  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif

" プラグインの管理
if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)
  let s:toml      = g:rc_dir . '/rc/dein.toml'
  call dein#load_toml(s:toml)
  call dein#end()
  call dein#save_state()
endif

" vimprocのインストール
if dein#check_install(['vimproc'])
  call dein#install(['vimproc'])
endif

if has('vim_starting') && dein#check_install()
    call dein#install()
endif

"----------------------------------------------
" 画面表示
"----------------------------------------------
syntax enable

" 色設定
let g:hybrid_use_iTerm_colors = 1
set background=dark
colorscheme hybrid
syntax on

" 行番号とカーソルラインの設定
set number
set cursorline
set ruler
hi LineNr ctermbg=0 ctermfg=8
hi CursorLineNr ctermbg=4 ctermfg=0
hi clear CursorLine

" 不可視文字の可視化
set list
set listchars=tab:▸\ ,eol:↲,extends:❯,precedes:❮

" 補完メニューの高さ
set pumheight=10

" 行が長くても全て表示
set display=lastline

" ステータスラインを常に表示する
set laststatus=2

set visualbell

" esc高速化
set timeout timeoutlen=1000 ttimeoutlen=50

"----------------------------------------------
" カーソル移動関連 
"----------------------------------------------
" オートインデント，改行，インサートモード開始時にバックスペースで削除
set backspace=indent,eol,start 
set whichwrap=b,s,h,l,<,>,[,]
set scrolloff=8
set sidescrolloff=16
set sidescroll=1

nnoremap <Space>h  ^
nnoremap <Space>l  $

" 改行挿入
nnoremap <Space>o  :<C-u>for i in range(v:count1) \| call append(line('.'), '') \| endfor<CR>
nnoremap <Space>O  :<C-u>for i in range(v:count1) \| call append(line('.')-1, '') \| endfor<CR>

" 括弧を入力した際に対応する括弧へ飛ぶ
set showmatch
set matchtime=1

" 行末までヤンク
nnoremap Y y$

" 入力モード中にj連打でESCに
inoremap jj <ESC>

" Ctrl + hjklで入力モードでのカーソル移動
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-h> <Left>
inoremap <C-l> <Right>

" Shift + hjkl でウィンドウ間を移動
nnoremap <S-h> <C-w>h
nnoremap <S-j> <C-w>j
nnoremap <S-k> <C-w>k
nnoremap <S-l> <C-w>l

" Shift + 矢印でウィンドウサイズを変更
nnoremap <S-Left>  <C-w><<CR>
nnoremap <S-Right> <C-w><CR>
nnoremap <S-Up>    <C-w>-<CR>
nnoremap <S-Down>  <C-w>+<CR>

" 画面送り
noremap <Space>j <c-f><cr><cr>
noremap <Space>k <c-b><cr><cr>

"Enterでいつでも一行挿入
" <Enter> always means inserting line.
map <S-Enter> O<ESC>
map <Enter> o<ESC>
"----------------------------------------------
" 検索／置換
"----------------------------------------------
set hlsearch
set incsearch
" 大文字小文字の区別をしない。混在時は区別する
set ignorecase
set smartcase
set wrapscan

"検索結果のハイライトをEsc連打でクリアする
nnoremap <ESC><ESC> :nohlsearch<CR>

" grep検索の設定
set grepformat=%f:%l:%m,%f:%l%m,%f\ \ %l%m,%f
set grepprg=grep\ -nh

" カーソル位置の単語で前方検索
nnoremap <Space>/ *<C-o>
nnoremap g<Space>/ g*<C-o>

"----------------------------------------------
" ファイル操作 
"----------------------------------------------
" バックアップ，スワップファイルの設定
set backupdir=$HOME/.vim/backup,$TEMP
set directory=$HOME/.vim/backup,$TEMP
if has('persistent_undo')
set undodir=~/.vim/undo
set undofile
endif

"クーロン用の設定
set backupskip=/tmp/*,/private/tmp/*,/private/tmp/crontab.*

"ファイルを開いた際に前回の編集を行った位置からスタート
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\""

" ファイルのリネーム
command! -nargs=1 -complete=file Rename f <args>|call delete(expand('#'))

set confirm
" バッファを保存しなくても他のバッファを表示
set hidden
set autoread

" 新しく開く代わりに既に開いてあるバッファを開く
set switchbuf=useopen

" vim内部で通常使用する文字エンコーディングを設定
set encoding=utf-8     
" 文字エンコーディングに使われるexpressionを定める
set charconvert=utf-8
" バッファのファイルエンコーディングを指定
set fileencoding=utf-8
" 既存ファイルを開く際の文字コード自動判別
set fileencodings=utf-8,euc-jp,sjis

" 保存するときにtabをspaceに変換するのを無効化
set noexpandtab

" 自動保存
set autowrite
set updatetime=500

" 自動保存は特定の場合にのみ適応
function s:AutoWriteIfPossible()
if &filetype == 'gitcommit'
  return
endif
if &modified && !&readonly && bufname('%') !=# '' && &buftype ==# '' && expand("%") !=# ''
  write
endif
endfunction
" 一定時間操作をしなかったりフォーカスを外した時に自動保存
autocmd CursorHold * call s:AutoWriteIfPossible() 
autocmd CursorHoldI * call s:AutoWriteIfPossible() 
autocmd FocusLost * call s:AutoWriteIfPossible()

" :e などでファイルを開く際にフォルダが存在しない場合は自動作成
function! s:mkdir(dir, force)
if !isdirectory(a:dir) && (a:force ||
      \ input(printf('"%s" does not exist. Create? [y/N]', a:dir)) =~? '^y\%[es]$')
  call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
endif
endfunction
autocmd BufWritePre * call s:mkdir(expand('<afile>:p:h'), v:cmdbang)

"----------------------------------------------
" タブ／インデント
"----------------------------------------------
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set autoindent
set smartindent

"----------------------------------------------
" コマンドライン
"----------------------------------------------

set wildmenu wildmode=list:longest,full
set history=10000
set showcmd
" コマンドラインの高さを2行に
set cmdheight=2

"----------------------------------------------
" 動作環境との統合
"----------------------------------------------

" yank内容をクリップボードと共有
if has('gui') || has('xterm_clipboard')
set clipboard=unnamed
endif

" インサートモードから抜けた時にIMEを無効化
set iminsert=2

" マウスの有効化
set mouse=a
set shellslash

"----------------------------------------------
" その他
"----------------------------------------------

"ノーマルモードではセミコロンをコロンに。
nnoremap ; :

" ファイルの保存関連
nnoremap <Space>w  :<C-u>w<CR>
nnoremap <Space>q  :<C-u>q<CR>
" 危険なコマンドは使わない
nnoremap ZZ <Nop>
nnoremap ZQ <Nop>

" sudo
if executable('sudo')
function! s:save_as_root(bang, filename) abort
  execute 'write' . a:bang '!sudo tee > /dev/null' (a:filename ==# '' ? '%' : a:filename)
endfunction
else
function! s:save_as_root(bang, filename) abort
  echoerr 'sudo is not supported in this environment'
endfunction
endif
command! -bar -bang -nargs=? -complete=file SudoWrite  call s:save_as_root('<bang>', <q-args>)

" カーソルキーを無効化
function! HardMode ()
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>
endfunction

function! EasyMode ()
noremap <Up> <Up>
noremap <Down> <Down>
noremap <Left> <Left>
noremap <Right> <Right>
endfunction

command! HardMode call HardMode()
command! EasyMode call EasyMode()
" 起動時にカーソル移動を無効化
autocmd VimEnter call HardMode()

"----------------------------------------------
" Markdownの設定
"----------------------------------------------

autocmd BufRead,BufNewFile *.{mkd,md} set filetype=markdown
autocmd! FileType markdown hi! def link markdownItalic Normal
autocmd FileType markdown set commentstring=<\!--\ %s\ -->
" for kannokanno/previm
let g:previm_open_cmd = 'open -a Safari'
nnoremap <silent> <C-p> :PrevimOpen<CR>
" for plasticboy/vim-markdown
let g:vim_markdown_no_default_key_mappings = 1
let g:vim_markdown_math = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_folding_style_pythonic = 1

" html
hi link htmlItalic LineNr
hi link htmlBold WarningMsg
hi link htmlBoldItalic ErrorMsg
"----------------------------------------------
" Unite 
"----------------------------------------------
" prefix keyを設定
nnoremap [unite] <Nop>
nmap f [unite]

" insertモードで開始しない
let g:unite_enable_start_insert = 0
" 大文字小文字を区別しない
let g:unite_enable_ignore_case = 1
let g:unite_enable_smart_case = 1
"最近開いたファイル履歴の保存数
let g:unite_source_file_mru_limit = 200
"file_mruの表示フォーマットを指定。空にすると表示スピードが高速化される
let g:unite_source_file_mru_filename_format = ''
" ブックマークディレクトリ
let g:unite_source_bookmark_directory = $HOME . '/.vim/bookmark'

"開いていない場合はカレントディレクトリ
nnoremap <silent> [unite]f :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
"バッファ一覧
nnoremap <silent> [unite]b :<C-u>Unite buffer<CR>
"レジスタ一覧
nnoremap <silent> [unite]r :<C-u>Unite -buffer-name=register register<CR>
"最近使用したファイル一覧
nnoremap <silent> [unite]m :<C-u>Unite file_mru<CR>
"ブックマーク一覧
nnoremap <silent> [unite]c :<C-u>Unite bookmark<CR>
"ブックマークに追加
nnoremap <silent> [unite]a :<C-u>UniteBookmarkAdd<CR>
" タグ
nnoremap <silent> [unite]t  :<C-u>Unite tag<CR>
" grep検索
nnoremap <silent> [unite]g :<C-u>Unite grep:. -buffer_name=search-buffer<CR>
" カーソル位置の単語をgrep検索
nnoremap <silent> [unite]cg :<C-u>Unite grep:. -buffer-name=search-buffer<CR><C-R><C-W>
" grep検索結果の再呼出
nnoremap <silent> [unite]r  :<C-u>UniteResume search-buffer<CR>

" UniteのgrepではSilver Seacrherを使う
if executable('ag')
  " Use ag in unite grep source.
  let g:unite_source_grep_command = 'ag'
  let g:unite_source_grep_recursive_opt = 'HRn'
  let g:unite_source_grep_default_opts =
  \ '--line-numbers --nocolor --nogroup --hidden --ignore ' .
  \  '''.hg'' --ignore ''.svn'' --ignore ''.git'' --ignore ''.bzr'''
endif

" よく使うコマンド 
let g:unite_source_menu_menus = {
\   "shortcut" : {
\       "description" : "unite-menu",
\       "command_candidates" : [
\           ["edit vimrc", "edit $MYVIMRC"],
\           ["edit gvimrc", "edit $MYGVIMRC"],
\           ["unite-file_mru", "Unite file_mru"],
\           ["Unite Beautiful Attack", "Unite -auto-preview colorscheme"],
\           ["unite-output:message", "Unite output:message"],
\       ],
\   },
\}

"vimFiler
let g:vimfiler_as_default_explorer = 1
let g:vimfiler_ignore_pattern='\(^\.\|\~$\|\.pyc$\|\.[oad]$\)'

" IDE風表示
noremap <C-X><C-T> :VimFiler -split -simple -winwidth=35 -no-quit<ENTER>
"現在開いているバッファのディレクトリを開く
nnoremap <silent> <Leader>fe :<C-u>VimFilerBufferDir -quit<CR>

"デフォルトのキーマッピングを変更
augroup vimrc
autocmd FileType vimfiler call s:vimfiler_my_settings()
augroup END
function! s:vimfiler_my_settings()
nmap <buffer> q <Plug>(vimfiler_exit)
nmap <buffer> Q <Plug>(vimfiler_hide)
endfunction
"---------------------------------------------
" context filetype
"---------------------------------------------
" コンテキストで切り替え
let g:context_filetype#filetypes = {
\	'shader' : [
\		{
\			'filetype' : 'glsl',
\			'start'    : 'GLSLPROGRAM',
\			'end'      : 'ENDGLSL'
\		}
\	],
\ }
"----------------------------------------------
" airline
"----------------------------------------------
"let g:airline_powerline_fonts = 1
"let g:airline_theme = 'molokai'
"----------------------------------------------
" neocomplete
"----------------------------------------------

let g:acp_enableAtStartup = 0
let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_ignore_case = 1
let g:neocomplete#enable_smart_case = 1
let g:neocomplete#sources#syntax#min_keyword_length = 3


" 日本語入力時、無効化
let g:neocomplete#lock_iminsert = 1

" オムニ補完
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'
if !exists('g:neocomplete#force_omni_input_patterns')
let g:neocomplete#force_omni_input_patterns = {}
endif
let g:neocomplete#force_omni_input_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'

" _(アンダースコア)区切りの補完を有効化
let g:neocomplete#enable_underbar_completion = 1
let g:neocomplete#enable_camel_case_completion  =  1

" ポップアップメニューで表示される候補の数
let g:neocomplete#max_list = 20

" 補完を表示する最小文字数
let g:neocomplete#auto_completion_start_length = 2

" ディレクトリ
let g:neocomplete#sources#dictionary#dictionaries = {
  \ 'default' : '',
  \ 'vimshell' : $HOME.'/.vimshell_hist',
  \ 'scheme' : $HOME.'/.gosh_completions'
      \ }

" キーバインド
inoremap <expr><C-g> neocomplete#undo_completion()
inoremap <expr><C-l> neocomplete#complete_common_string()
" 改行するとインデントがおかしくなるので修正
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
return pumvisible() ? "\<C-y>" : "\<CR>"
endfunction
inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><C-y> neocomplete#close_popup() :"<ESC>$i"
inoremap <expr><C-e> neocomplete#cancel_popup()

inoremap <expr><CR>  pumvisible() ? neocomplcache#close_popup() : "<CR>"
"----------------------------------------------
" 実験的な場所 
"----------------------------------------------
" 1 が設定されていれば有効になる
let g:enable_highlight_cursor_word = 0
" let g:enable_highlight_cursor_word = 1


augroup highlight-cursor-word
    autocmd!
    autocmd CursorMoved * call s:hl_cword()
    " カーソル移動が重くなったと感じるようであれば
    " CursorMoved ではなくて
    " CursorHold を使用する
"     autocmd CursorHold * call s:hl_cword()
    " 単語のハイライト設定
    autocmd ColorScheme * highlight CursorWord guifg=Red
    " アンダーラインでハイライトを行う場合
"     autocmd ColorScheme * highlight CursorWord gui=underline guifg=NONE
    autocmd BufLeave * call s:hl_clear()
    autocmd WinLeave * call s:hl_clear()
    autocmd InsertEnter * call s:hl_clear()
augroup END


function! s:hl_clear()
    if exists("b:highlight_cursor_word_id") && exists("b:highlight_cursor_word")
        silent! call matchdelete(b:highlight_cursor_word_id)
        unlet b:highlight_cursor_word_id
        unlet b:highlight_cursor_word
    endif
endfunction

function! s:hl_cword()
    let word = expand("<cword>")
    if    word == ""
    return
    endif
    if get(b:, "highlight_cursor_word", "") ==# word
        return
    endif

    call s:hl_clear()
    if !g:enable_highlight_cursor_word
        return
    endif

    if !empty(filter(split(word, '\zs'), "strlen(v:val) > 1"))
        return
    endif

    let pattern = printf("\\<%s\\>", expand("<cword>"))
    silent! let b:highlight_cursor_word_id = matchadd("CursorWord", pattern)
    let b:highlight_cursor_word = word
endfunction

" vimからwebAPIを叩くテスト
function! s:ChatworkSay(message)
  let token='APIのトークン'
  let room_id='投稿するroom_id'
  let url='https://api.chatwork.com/v1/rooms/' . room_id
  
  " messageをPOSTする
  let ret = webapi#http#post(url. '/messages/', {'body': a:messaage},
        \ {'X-ChatworkToken' : token})
  let dict = webapi#json#decode(res.content)
  " message_idをecho
  echo dict.message_id
endfunction

command! -nargs=1 ChatworkSay :call s:ChatworkSay(<f-args>)


"----------------------------------------------
" kobito 連携
"----------------------------------------------
function! s:open_kobito(...)
    if a:0 == 0
        call system('open -a Kobito '.expand('%:p'))
    else
        call system('open -a Kobito '.join(a:000, ' '))
    endif
endfunction
" 引数のファイル(複数指定可)を Kobitoで開く
" （引数無しのときはカレントバッファを開く
command! -nargs=* Kobito call s:open_kobito(<f-args>)
" Kobito を閉じる
command! -nargs=0 KobitoClose call system("osascript -e 'tell application \"Kobito\" to quit'")
" Kobito にフォーカスを移す
command! -nargs=0 KobitoFocus call system("osascript -e 'tell application \"Kobito\" to activate'")

"----------------------------------------------
" 最後に読み込む設定
"----------------------------------------------
" カレントディレクトリ内の.vimrcを読まない
set secure
