if exists('g:loaded_plugin_gem') 
  finish
endif
let g:loaded_plugin_gem = 1

" Init {{{1

let s:gem = { }

augroup gemPluginDetect
  autocmd!
  autocmd VimEnter * call s:Detect()
augroup END

function! s:Detect()
	if len(glob('*.gemspec')) == 0
		return 
	endif

	let s:gem.path = getcwd()

	call s:Init()
endfunc


function! s:Init()
  call s:Command()
endfunc

function! s:Command()
  command! -nargs=1 -complete=customlist,s:complete_lib    Rl   :call s:Rlib(<q-args>)
  command! -nargs=1 -complete=customlist,s:complete_spec   Rs   :call s:Rspec(<q-args>)
  command! -nargs=1 -complete=customlist,s:complete_bin    Rb   :call s:Rbin(<q-args>)
  command! -nargs=1 -complete=customlist,s:complete_nil    R   :call s:R(<q-args>)
  command! -nargs=0 A   :call s:Alternative()
  command! -nargs=0 Rtags  :call s:Rtags()
  if exists(":NERDTree")
    command! -nargs=? Rtree :NERDTree `=s:gem.path`
	endif
endfunc
" }}}1
" Command func {{{1
function! s:Rlib(name)
	if ! s:complete_is_called
		call s:complete_lib(a:name, '', 0)
		let s:complete_is_called = 0
	endif

	let path = get(s:complete_files, a:name, 'lib/'.a:name)
	edit `=path`
endfunc

function! s:Rspec(name)
	if ! s:complete_is_called
		call s:complete_spec(a:name, '', 0)
		let s:complete_is_called = 0
	endif

	let path = get(s:complete_files, a:name, 'spec/'.a:name)
	edit `=path`
endfunc

function! s:Rbin(name)
	if ! s:complete_is_called
		call s:complete_bin(a:name, '', 0)
		let s:complete_is_called = 0
	endif

	let path = get(s:complete_files, a:name, 'bin/'.a:name)
	edit `=path`
endfunc

function! s:Rtags()
	let cmd = "ctags -R " . s:gem.path
	call system(cmd)
endfunc

function! s:R(name)
	if ! s:complete_is_called
		call s:complete_nil(a:name, '', 0)
		let s:complete_is_called = 0
	endif


	let path = get(s:complete_files, a:name, '')
	if len(path) == 0
		if match(expand('%'), '^spec') != -1 
			let dir = 'spec/' 
		else
			let dir = 'lib/'
		endif
		let path = dir . a:name
	endif

	edit `=path`
endfunc


" }}}1
" complete func {{{1

"
" (normal) x 
" 	# priority: from high to low
"   lib/*.rb
"   lib/*/*.rb+dir
"   cur-file-dir/*.rb+dir
"
" (dir) ffi/x
"
"   lib/ffi/*.rb+dir
"
let s:complete_files={}
let s:complete_is_called = 0

function! s:complete_lib(ArgLead, CmdLine, CursorPos)
	let s:complete_is_called = 1
	let files = {}

	if stridx(a:ArgLead, '/') != -1
		let dir = fnamemodify(a:ArgLead, ':h')
		call extend(files, s:glob_gem(expand('%:h'), dir.'/*', '\v(.*)\.rb'))
	 	call extend(files, s:glob_gem('lib/*', dir.'/*', '\v(.*)\.rb'))
	 	call extend(files, s:glob_gem('lib', dir.'/*', '\v(.*)\.rb'))
	else
		call extend(files, s:glob_gem('lib', '*', '\v(.*)\.rb'))
		call extend(files, s:glob_gem('lib/*', '*', '\v(.*)\.rb'))
		call extend(files, s:glob_gem(expand('%:h'), '*', '\v(.*)\.rb'))
	endif
	let s:complete_files = files

	return s:filter(keys(files), '^'.a:ArgLead)
endfunc

function! s:complete_spec(ArgLead, CmdLine, CursorPos)
	let s:complete_is_called = 1
	let files = {}

	if stridx(a:ArgLead, '/') != -1
		let dir = fnamemodify(a:ArgLead, ':h')
		call extend(files, s:glob_gem(expand('%:h'), dir.'/*', '\v(.*)_spec\.rb'))
	 	call extend(files, s:glob_gem('spec/*', dir.'/*', '\v(.*)_spec\.rb'))
	 	call extend(files, s:glob_gem('spec', dir.'/*', '\v(.*)_spec\.rb'))
	else
		call extend(files, s:glob_gem('spec', '*.rb', '\v(.*)_spec\.rb'))
		call extend(files, s:glob_gem('spec/*', '*', '\v(.*)_spec\.rb'))
		call extend(files, s:glob_gem(expand('%:h'), '*', '\v(.*)_spec\.rb'))
	endif
	" spec_helper.rb is special
	let files['helper'] = 'spec/spec_helper.rb'
	let s:complete_files = files

	return s:filter(keys(files), '^'.a:ArgLead)
endfunc
function! s:complete_bin(ArgLead, CmdLine, CursorPos)
	let s:complete_is_called = 1
	let files = s:glob_gem('bin', '*', '\v(.*)')
	let s:complete_files = files
	return s:filter(keys(files), '^'.a:ArgLead) 
endfunc

function! s:complete_nil(ArgLead, CmdLine, CursorPos)
	let cur_file = expand('%')
	if match(cur_file, '^spec') != -1
		return s:complete_spec(a:ArgLead, a:CmdLine, a:CursorPos)
	else
		return s:complete_lib(a:ArgLead, a:CmdLine, a:CursorPos)
	end
endfunc


" }}}1

" Alternative {{{1
function! s:Alternative()
	let file = expand('%')
	if match(file, '\v^lib/|/lib/') != -1
		let file = s:lib2spec(file)
	elseif match(file, '\v^spec/|/spec/') != -1
		let file = s:spec2lib(file)
	else
		return
	endif

	edit `=file`
endfunc

function! s:lib2spec(path)
	let path = substitute(a:path, '\v^lib/', 'spec/', '')
	let path = substitute(path, '/lib/', '/spec/', '')
	let path = substitute(path, '\.rb$', '_spec.rb', '')
	return path
endfunc

function! s:spec2lib(path)
	let path = substitute(a:path, '\v^spec/', 'lib/', '')
	let path = substitute(path, '/spec/', '/lib/', '')
	let path = substitute(path, '_spec\.rb$', '.rb', '')
	return path
endfunc

" }}}1

" complete helper func {{{1

"
" filter pat from list
"
function! s:filter(lists, pat)
	let ret = []
	for key in a:lists
		if match(key, a:pat) != -1
			call add(ret, key)
		end
	endfor
	return ret
endfunc

"
" lib/
"   a.rb
"   a/
"
" glob_gem('lib') 
"   => {
"     'a': 'lib/a.rb' 
"     'a/': 'lib/a'
"    }
"
"
" glob_gem('lib', '*.rb') #=>  { 'a': 'lib/a.rb'} 
"   only *.rb file, no directory
"
" glob_gem('lib/*', 'ffi/*')  #=> {'ffi/a': lib/hello/ffi/a.rb'}
"
" @overload s:glob_gem(dir, glob, pat)
function! s:glob_gem(path, glob, pat)
	let ret = {}

	for dir in split(glob(a:path), '\n')
		if isdirectory(dir)
			call extend(ret, s:glob_gem_dir(dir, a:glob, a:pat))
		endif
	endfor

	return ret
endfunc

" @param [String] dir only one directory
function! s:glob_gem_dir(dir, glob, pat)
	let ret={}

	let paths_str = globpath(a:dir, a:glob)
	let paths = split(paths_str, '\n')
	for path in paths
		" skip *~
		if match(path, '.*[~]') != -1
			continue
		endif

		let file = copy(path)
		if isdirectory(path)
			let file = file . '/'
		else
			let file = get(matchlist(file, a:pat), 1, '')
			if len(file) == 0
				continue
			endif
		endif
		let file = file[strlen(a:dir.'/'):-1]
		let ret[file]=path
	endfor

	return ret
endfunc
" }}}1

" vim: foldmethod=marker
