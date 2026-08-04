# ~/.config/bash/conf.d/01-eza.bash
# eza setup

if ! has_cmd eza; then
  return 0
fi

EZA_DEFAULT_OPTS=(
  --color=auto
  --group-directories-first
  --icons=auto
  "--ignore-glob=.DS_Store"
  -s Name
)

# Replace ls with eza when available
unalias l ls ll ld lt llt 2>/dev/null

l()   { command eza -lh   "${EZA_DEFAULT_OPTS[@]}" "$@"; }
ls()  { command eza -1    "${EZA_DEFAULT_OPTS[@]}" "$@"; }
ll()  { command eza -lhag "${EZA_DEFAULT_OPTS[@]}" "$@"; }
ldr() { command eza -lhD  "${EZA_DEFAULT_OPTS[@]}" "$@"; }
lt()  { command eza -T    "${EZA_DEFAULT_OPTS[@]}" "$@"; }
llt() { command eza -lagT "${EZA_DEFAULT_OPTS[@]}" "$@"; }
