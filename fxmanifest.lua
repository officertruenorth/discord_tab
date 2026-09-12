fx_version 'cerulean'
game 'gta5'

name 'discord_tab'
description 'FiveM scoreboard with discordapi bridge integration'
author 'officertruenorth'
version '1.0.0'

lua54 'yes'

shared_script 'config.lua'

server_script 'server/main.lua'
client_script 'client/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
