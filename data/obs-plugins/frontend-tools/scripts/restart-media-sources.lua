-- Restart Media Sources
-- ---------------------------------------------------------------------------
-- Lets you manually restart IP-camera / media sources WITHOUT enabling
-- "Restart playback when source becomes active" (which causes visual glitches
-- every time a scene is shown).
--
-- Provides two things:
--   1) Buttons in this Scripts window (a stand-in for the Media Controls dock).
--   2) Two hotkeys you assign under Settings -> Hotkeys (search "Restart"):
--        * Restart ALL media sources
--        * Restart media sources in CURRENT scene
--
-- Works on both Media Source (ffmpeg_source) and VLC Video Source (vlc_source).
-- Note: for network/RTSP cameras a restart re-opens the stream, so expect a
-- brief reconnect/black frame -- that is inherent to tearing down the stream.
-- ---------------------------------------------------------------------------

obs = obslua

local hotkey_all   = obs.OBS_INVALID_HOTKEY_ID
local hotkey_scene = obs.OBS_INVALID_HOTKEY_ID

-- Source types OBS can restart as media. Matched by id (avoids bitwise ops,
-- which OBS's Lua 5.1 does not support). Add ids here if you use others.
local MEDIA_IDS = {
    ffmpeg_source = true,  -- Media Source
    vlc_source    = true,  -- VLC Video Source
    slideshow     = true,  -- Image Slide Show
}

local function is_media_source(source)
    if source == nil then return false end
    return MEDIA_IDS[obs.obs_source_get_unversioned_id(source)] == true
end

-- Re-applies the source's own settings, which forces a full re-init /
-- reconnect -- exactly what clicking OK in Properties does. This is what
-- reliably restarts live/network sources; obs_source_media_restart() only
-- seeks local media files and does nothing for an RTSP/network stream.
-- Returns 1 if it acted on the source, 0 otherwise.
local function restart_source(source)
    if not is_media_source(source) then return 0 end
    local settings = obs.obs_source_get_settings(source)
    obs.obs_source_update(source, settings)   -- reconnects network streams
    obs.obs_data_release(settings)
    obs.obs_source_media_restart(source)      -- also restarts local files
    return 1
end

-- Restart every media source in the whole scene collection.
local function restart_all()
    local count = 0
    local sources = obs.obs_enum_sources()
    if sources ~= nil then
        for _, source in ipairs(sources) do
            count = count + restart_source(source)
        end
    end
    obs.source_list_release(sources)
    obs.script_log(obs.LOG_INFO,
        string.format("Restart ALL: restarted %d media source(s).", count))
end

-- Restart only the media sources used in the current program scene
-- (descends into groups).
local function restart_current_scene()
    local scene_source = obs.obs_frontend_get_current_scene()
    if scene_source == nil then return end

    local count = 0
    local scene = obs.obs_scene_from_source(scene_source)
    local items = obs.obs_scene_enum_items(scene)
    if items ~= nil then
        for _, item in ipairs(items) do
            count = count + restart_source(obs.obs_sceneitem_get_source(item))
            if obs.obs_sceneitem_is_group(item) then
                local gitems = obs.obs_sceneitem_group_enum_items(item)
                if gitems ~= nil then
                    for _, gitem in ipairs(gitems) do
                        count = count + restart_source(obs.obs_sceneitem_get_source(gitem))
                    end
                    obs.sceneitem_list_release(gitems)
                end
            end
        end
        obs.sceneitem_list_release(items)
    end

    obs.obs_source_release(scene_source)
    obs.script_log(obs.LOG_INFO,
        string.format("Restart CURRENT scene: restarted %d media source(s).", count))
end

-- --- Hotkey callbacks ------------------------------------------------------

local function on_hotkey_all(pressed)
    if pressed then restart_all() end
end

local function on_hotkey_scene(pressed)
    if pressed then restart_current_scene() end
end

-- --- Script UI -------------------------------------------------------------

function script_description()
    return [[<b>Restart Media Sources</b><br/>
Manually restart IP-camera / media sources without using
"Restart playback when source becomes active".<br/><br/>
Use the buttons below, or assign hotkeys under
<b>Settings &rarr; Hotkeys</b> (search "Restart").]]
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_button(props, "btn_all",
        "Restart ALL media sources now",
        function() restart_all(); return false end)
    obs.obs_properties_add_button(props, "btn_scene",
        "Restart current-scene media now",
        function() restart_current_scene(); return false end)
    return props
end

-- --- Load / save hotkey bindings ------------------------------------------

function script_load(settings)
    hotkey_all = obs.obs_hotkey_register_frontend(
        "restart_all_media", "Restart ALL media sources", on_hotkey_all)
    local a = obs.obs_data_get_array(settings, "restart_all_media")
    obs.obs_hotkey_load(hotkey_all, a)
    obs.obs_data_array_release(a)

    hotkey_scene = obs.obs_hotkey_register_frontend(
        "restart_scene_media", "Restart media sources in CURRENT scene",
        on_hotkey_scene)
    local b = obs.obs_data_get_array(settings, "restart_scene_media")
    obs.obs_hotkey_load(hotkey_scene, b)
    obs.obs_data_array_release(b)
end

function script_save(settings)
    local a = obs.obs_hotkey_save(hotkey_all)
    obs.obs_data_set_array(settings, "restart_all_media", a)
    obs.obs_data_array_release(a)

    local b = obs.obs_hotkey_save(hotkey_scene)
    obs.obs_data_set_array(settings, "restart_scene_media", b)
    obs.obs_data_array_release(b)
end
