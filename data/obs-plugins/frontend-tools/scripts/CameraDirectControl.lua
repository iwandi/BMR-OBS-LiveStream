obs = obslua

scene_name = "CameraSelect"
camera_count = 16
camera_sources = {}
for i = 1, camera_count do
    camera_sources[i] = string.format("Cam %02d", i)
end

hotkey_objects = {}

-- Helper: get scene object
function get_scene(name)
    local source = obs.obs_get_source_by_name(name)
    if source == nil then return nil end
    local scene = obs.obs_scene_from_source(source)
    obs.obs_source_release(source)
    return scene
end

-- Switch camera inside CameraSelect only
function switch_camera(target_camera)
    local scene = get_scene(scene_name)
    if scene == nil then return end

    for _, cam_name in ipairs(camera_sources) do
        local item = obs.obs_scene_find_source(scene, cam_name)
        if item ~= nil then
            obs.obs_sceneitem_set_visible(item, cam_name == target_camera)
        end
    end
end

-- Restore all cameras visible inside CameraSelect
function restore_all_cameras()
    local scene = get_scene(scene_name)
    if scene == nil then return end

    for _, cam_name in ipairs(camera_sources) do
        local item = obs.obs_scene_find_source(scene, cam_name)
        if item ~= nil then
            obs.obs_sceneitem_set_visible(item, true)
        end
    end
end

-- Register hotkeys
function script_load(settings)
    local hotkeys = {}
    for i = 1, camera_count do
        local cam_name = camera_sources[i]
        hotkeys[i] = {
            id = "camera"..i,
            func = function() switch_camera(cam_name) end
        }
    end
    hotkeys[#hotkeys + 1] = {id = "restore_all", func = restore_all_cameras}

    for _, hk in ipairs(hotkeys) do
        local hotkey_obj = obs.obs_hotkey_register_frontend(hk.id, "Switch "..hk.id, hk.func)
        hotkey_objects[hk.id] = hotkey_obj

        local hotkey_save_array = obs.obs_data_get_array(settings, hk.id)
        obs.obs_hotkey_load(hotkey_obj, hotkey_save_array)
        obs.obs_data_array_release(hotkey_save_array)
    end
end

function script_save(settings)
    for id, hotkey_obj in pairs(hotkey_objects) do
        local hotkey_array = obs.obs_hotkey_save(hotkey_obj)
        obs.obs_data_set_array(settings, id, hotkey_array)
        obs.obs_data_array_release(hotkey_array)
    end
end

function script_description()
    return "Switch cameras inside 'CameraSelect' by toggling scene item visibility only. Adds restore-all function."
end
