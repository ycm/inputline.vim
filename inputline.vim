vim9script

import './keycodes.vim'

highlight! InputLineCursor cterm=inverse gui=inverse

# Implements a fixed-width input line using +popup_win.
# <NOTE> does not support multibyte characters
export class InputLine
    var _id = -1
    var _text: string
    var _prompt: string
    var _cursor: number
    var _popup_width: number
    var _prompt_text_prop: dict<any>
    var _input_enter_callback: func
    var _x_offset = 0
    var _currently_pasting = false
    var _paste_string = ''

    def new(text: string = '',
            prompt_text: string = '> ',
            popup_width: number = 80,
            Callback_func: func = (v) => v)
        this._text = text
        this._prompt = prompt_text
        this._popup_width = popup_width
        this._cursor = text->len()
        this._input_enter_callback = Callback_func

        if prop_type_get('prop_ycm_inputline_normal') == {}
            prop_type_add('prop_ycm_inputline_normal', {highlight: 'Normal'})
        endif
        if prop_type_get('prop_ycm_inputline_cursor') == {}
            prop_type_add('prop_ycm_inputline_cursor', {highlight: 'InputLineCursor'})
        endif
        if prop_type_get('prop_ycm_inputline_prompt') == {}
            prop_type_add('prop_ycm_inputline_prompt', {highlight: 'Keyword'})
        endif

        this._prompt_text_prop = {
            col: 1,
            length: this._prompt->len(),
            type: 'prop_ycm_inputline_prompt'
        }
    enddef

    def Open()
        this._id = popup_create(this._get_curr_formatted_line(), {
            border: [],
            borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
            title: ' My Title ',
            minwidth: this._popup_width,
            maxwidth: this._popup_width,
            borderhighlight: ['Constant'],
            highlight: 'Normal',
            wrap: false,
            padding: [0, 1, 0, 1],
            filter: this._consume_keys,
            mapping: false,
        })
    enddef

    def _get_curr_formatted_line(): list<dict<any>>
        var visual_width = this._popup_width - this._prompt->len()

        # shift window if cursor is too far right
        this._x_offset = [this._x_offset, this._cursor - visual_width + 1]->max()
        # shift window if cursor is too far left
        if this._cursor - this._x_offset < (visual_width - 1) / 2
            this._x_offset = [0, this._cursor - (visual_width - 1) / 2]->max()
        endif

        var text_prop = {
            col: this._prompt->len() + 1,
            length: this._text[this._x_offset : ]->len(),
            type: 'prop_ycm_inputline_normal'
        }
        var cursor_prop = {
            col: this._prompt->len() + this._cursor - this._x_offset + 1,
            length: 1,
            type: 'prop_ycm_inputline_cursor'
        }

        var text_with_cursor = this._cursor >= this._text->len() ? this._text .. ' ' : this._text

        return [{
            text: this._prompt .. text_with_cursor[this._x_offset :],
            props: [this._prompt_text_prop, cursor_prop, text_prop]
        }]
    enddef

    def _insert(str: string)
        if this._cursor == 0
            this._text = str .. this._text[this._cursor :]
        else
            this._text = this._text[: this._cursor - 1] .. str .. this._text[this._cursor :]
        endif
        this._cursor += str->len()
        this._refresh()
    enddef

    def _refresh()
        this._id->popup_settext(this._get_curr_formatted_line())
    enddef

    def _handle_special_key(key: string)
        var key_norm = keycodes.NormalizeKey(key)
        if key_norm ==? '<esc>'
            this._id->popup_close()
            return
        elseif key_norm ==? '<paste-start>'
            this._currently_pasting = true
        elseif key_norm ==? '<paste-end>'
            this._insert(this._paste_string)
            this._currently_pasting = false
            this._paste_string = ''
        elseif this._currently_pasting
            return
        elseif key_norm ==? '<cr>'
            this._input_enter_callback(this._text)
            this._id->popup_close()
            return
        elseif key_norm ==? '<left>'
            this._cursor = [0, this._cursor - 1]->max()
        elseif key_norm ==? '<right>'
            this._cursor = [this._text->len(), this._cursor + 1]->min()
        elseif ['<home>', '<c-a>']->index(key_norm->tolower()) >= 0
            this._cursor = 0
        elseif ['<end>', '<c-e>']->index(key_norm->tolower()) >= 0
            this._cursor = this._text->len()
        elseif key_norm ==? '<bs>' && this._cursor > 0
            this._text = this._text->slice(0, this._cursor - 1)
                .. this._text->slice(this._cursor)
            --this._cursor
        elseif key_norm ==? '<del>' && this._cursor < this._text->len()
            this._text = this._text->slice(0, this._cursor)
                .. this._text->slice(this._cursor + 1)
        endif
        this._refresh()
    enddef

    def _consume_keys(id: number, key: string): bool
        if key->len() != 1 || key->char2nr() < 32 || key->char2nr() > 126
            this._handle_special_key(key)
        elseif this._currently_pasting
            this._paste_string = this._paste_string .. key
        else
            this._insert(key)
        endif
        return true
    enddef

endclass
