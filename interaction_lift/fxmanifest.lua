fx_version 'cerulean'
game 'gta5'

author 'ShowZx'
description 'description here'
version '0.9'

client_script { 'client/config.lua', 
'client/pullup.lua', 
'client/legsup.lua',
'client/main.lua',
'client/support.lua',
'client/function.lua',
'client/integrations/esx.lua',
'client/integrations/qb.lua',
'client/integrations/ox_target.lua',
'client/integrations/qb_target.lua',
'client/integrations/proxy.lua'

}

server_script {'server/main.lua'}