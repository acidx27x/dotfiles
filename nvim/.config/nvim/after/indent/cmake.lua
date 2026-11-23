-- Match block keywords so an ordinary command's opening parenthesis keeps its indent.
vim.opt_local.indentkeys:remove({
  "=ENDIF(",
  "ENDFOREACH(",
  "ENDMACRO(",
  "ELSE(",
  "ELSEIF(",
  "ENDWHILE(",
})
vim.opt_local.indentkeys:append({
  "=~endif(",
  "=~endforeach(",
  "=~endmacro(",
  "=~else(",
  "=~elseif(",
  "=~endwhile(",
})
