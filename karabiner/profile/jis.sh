#!/bin/sh

cli=/Applications/Karabiner.app/Contents/Library/bin/karabiner

$cli set option.vimode_control_hjkl 1
/bin/echo -n .
$cli set remap.doublepresscommandQ 1
/bin/echo -n .
$cli set remap.jis_command2eisuukana_prefer_command 1
/bin/echo -n .
$cli set repeat.initial_wait 150
/bin/echo -n .
$cli set repeat.wait 20
/bin/echo -n .
/bin/echo
