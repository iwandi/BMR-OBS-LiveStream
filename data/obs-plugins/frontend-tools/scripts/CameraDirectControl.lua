obs = obslua

scene_name = "CameraSelect"
camera_sources = {
    "Cam 01","Cam 02","Cam 03","Cam 04","Cam 05","Cam 06","Cam 07","Cam 08","Cam 09"
}

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

-- Individual hotkey functions
function switch_camera_1() switch_camera("Cam 01") end
function switch_camera_2() switch_camera("Cam 02") end
function switch_camera_3() switch_camera("Cam 03") end
function switch_camera_4() switch_camera("Cam 04") end
function switch_camera_5() switch_camera("Cam 05") end
function switch_camera_6() switch_camera("Cam 06") end
function switch_camera_7() switch_camera("Cam 07") end
function switch_camera_8() switch_camera("Cam 08") end
function switch_camera_9() switch_camera("Cam 09") end

-- Register hotkeys
function script_load(settings)
    local hotkeys = {
        {id = "camera1", func = switch_camera_1},
        {id = "camera2", func = switch_camera_2},
        {id = "camera3", func = switch_camera_3},
        {id = "camera4", func = switch_camera_4},
        {id = "camera5", func = switch_camera_5},
        {id = "camera6", func = switch_camera_6},
        {id = "camera7", func = switch_camera_7},
        {id = "camera8", func = switch_camera_8},
        {id = "camera9", func = switch_camera_9},
        {id = "restore_all", func = restore_all_cameras}
    }

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
