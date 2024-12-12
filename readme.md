# inputline.vim

![demo](https://github.com/ycm/inputline.vim/blob/master/demo.gif)

A minimal example demonstrating how to simulate an input line with `+popup_win`. This documentation is written for my future reference but others might find it useful.

By design `+popup_win` is restrictive and eschews built-ins to edit or input text. In cases where it's reasonable to ingest input through a popup window, this functionality can be simulated without too much work.

## Basics

The input line example offers the following functionalities, which should be the bare minimum:

- Cursor is visible at all times
- Scrolls horizontally in a reasonable way
- On `<Enter>` invokes a custom callback
- On `<Esc>` does not invoke the callback
- Is exposed to standard ASCII input (33 through 126)
- Is exposed to familiar movement keys (left/right/home/end)
- Is exposed to `paste`
- Ignores nonstandard pasted text (i.e. line breaks should not be ingested when pasting)
- Optionally provide an initial input instead of presenting a blank line

The example *does not* handle multibyte input since I consider that nonessential. To implement multibyte character support, use `strgetchar` and `charidx` and check for off-by-1s carefully.

## Cursor

Use a space character to represent a cursor at the end of the input; visually distinguish the cursor with a highlight group and a corresponding text property via `prop_type_add`.

## Usage

Define a callback:
```
def EchoMyInput(str: string)
    echom $'received input: <{str}>'
enddef
```

Create an input line object:
```
var input_line = InputLine.new('starting text', 'Prompt > ', 40, EchoMyInput)
```

Define arbitrary ways to invoke the input line:
```
command! OpenInputLine input_line.Open()
nnoremap <silent> <leader>p :OpenInputLine<cr>
```
