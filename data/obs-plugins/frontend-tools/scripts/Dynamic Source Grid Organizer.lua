obs = obslua
math = require("math")

interval = 200


pt_BR={"Idioma (Recarregue)", "Cena", "Prefixo das Fontes", "Espaçamento entre Fontes", "Margem", "Deslocamento Horizontal", "Deslocamento Vertical", "Tela Dividida para 2 Fontes"}
en_US={"Language (Reload)", "Scene", "Source Prefix", "Source Spacing", "Margin", "X-Axis Offset", "Y-Axis Offset", "Split Screen for 2 Sources"}
es_ES={"Idioma (Recargar)", "Escena", "Prefijo de las Fuentes", "Espaciado entre Fuentes", "Margen", "Desplazamiento en Eje X", "Desplazamiento en Eje Y", "Pantalla Dividida para 2 Fuentes"}
zh_CN={"语言（重新加载）", "场景", "源前缀", "源间距", "边距", "X轴偏移", "Y轴偏移", "两源分屏"}
ru_RU={"Язык (Перезагрузка)", "Сцена", "Префикс источников", "Расстояние между источниками", "Край", "Смещение по оси X", "Смещение по оси Y", "Разделенный экран для 2 источников"}
ja_JP={"言語（再読み込み）", "シーン", "ソース接頭辞", "ソース間隔", "余白", "X軸オフセット", "Y軸オフセット", "2つのソースの分割画面"}
de_DE={"Sprache (Neu laden)", "Szene", "Quellenpräfix", "Quellenabstand", "Rand", "X-Achsenverschiebung", "Y-Achsenverschiebung", "Geteilter Bildschirm für 2 Quellen"}


languages = {"English", "Português", "Español", "中文", "Русский", "日本語", "Deutsch"}

language_name = "English"
language = {"Language (Reload)", "Scene", "Source Prefix", "Source Spacing", "Margin", "X-Axis Offset", "Y-Axis Offset", "Split Screen for 2 Sources"}


scene_name = ""
source_prefix = false
spacing = 20
margin = 0
x_offset = 0
y_offset = 0

video_info = obs.obs_video_info()
obs.obs_get_video_info(video_info)
screen_width = video_info.base_width
screen_height = video_info.base_height

browser_sources = {}

aspect_ratio = 16 / 9

script_active = true

split_screen = false

function process_browsers()
    if not script_active or not source_prefix then return end

    local scene = obs.obs_get_scene_by_name(scene_name)
    if not scene then
        obs.obs_scene_release(scene)
        return
    end

    local scene_items = obs.obs_scene_enum_items(scene)
    if not scene_items then
        obs.obs_scene_release(scene)
        return
    end

    local active_browsers = {}
    local inactive_browsers = {}

    for _, scene_item in ipairs(scene_items) do
        local source = obs.obs_sceneitem_get_source(scene_item)
        local source_name = obs.obs_source_get_name(source)

        if string.match(source_name, "^" .. source_prefix) then
            if obs.obs_sceneitem_visible(scene_item) then
                table.insert(active_browsers, scene_item)
            else
                table.insert(inactive_browsers, scene_item)
            end
        end
    end

    table.sort(active_browsers, function(a, b)
        local name_a = obs.obs_source_get_name(obs.obs_sceneitem_get_source(a))
        local name_b = obs.obs_source_get_name(obs.obs_sceneitem_get_source(b))
        return name_a < name_b
    end)

    handle_browsers(active_browsers, inactive_browsers)

    obs.sceneitem_list_release(scene_items)
    obs.obs_scene_release(scene)
end

function handle_browsers(active_browsers, inactive_browsers)
    if not script_active or not source_prefix then return end
    local total_browsers = #active_browsers
    if total_browsers == 0 then
        return
    end

    if total_browsers == 2 and split_screen then
        for index, browser in ipairs(active_browsers) do
            if browser then
                local s = obs.obs_sceneitem_get_source(browser)
                local width = obs.obs_source_get_width(s)
                local height = obs.obs_source_get_height(s)

                local position = obs.vec2()
                position.x = (index - 1) * (screen_width / 2)
                position.y = 0
                obs.obs_sceneitem_set_pos(browser, position)

                local crop = obs.obs_sceneitem_crop()
                crop.left = width / 4
                crop.right = width / 4
                crop.top = 0
                crop.bottom = 0
                obs.obs_sceneitem_set_crop(browser, crop)

                local scale = obs.vec2()
                scale.x = screen_width / width
                scale.y = screen_height / height
                obs.obs_sceneitem_set_scale(browser, scale)
            end
        end

    else
        local cols = math.ceil(math.sqrt(total_browsers))
        local rows = math.ceil(total_browsers / cols)

        local unavailable_space = 2 * margin

        local available_width = screen_width - unavailable_space
        local available_height = screen_height - unavailable_space

        local total_spacing_x = (cols - 1) * spacing
        local total_spacing_y = (rows - 1) * spacing

        local browser_width = (available_width - total_spacing_x) / cols
        local browser_height = (available_height - total_spacing_y) / rows

        if browser_width / aspect_ratio <= browser_height then
            browser_height = browser_width / aspect_ratio
        else
            browser_width = browser_height * aspect_ratio
        end

        local total_content_height = rows * browser_height + (rows - 1) * spacing
        local vertical_padding = (available_height - total_content_height) / 2

        for row = 0, rows - 1 do
            local row_items = math.min(cols, total_browsers - row * cols)
            local total_row_width = row_items * browser_width + (row_items - 1) * spacing
            local horizontal_padding = (available_width - total_row_width) / 2

            for col = 0, row_items - 1 do
                local index = row * cols + col
                if index < #active_browsers then
                    local x = margin + horizontal_padding + col * (browser_width + spacing)
                    local y = margin + vertical_padding + row * (browser_height + spacing)

                    local browser = active_browsers[index + 1]
                    if browser then
                        local s = obs.obs_sceneitem_get_source(browser)
                        local width = obs.obs_source_get_width(s)
                        local height = obs.obs_source_get_height(s)

                        show_browser(browser, x, y, browser_width / width, browser_height / height)
                    end
                end
            end
        end
    end

    for _, browser in ipairs(inactive_browsers) do
        hide_browser(browser)
    end
end

function show_browser(scene_item, x, y, x_scale, y_scale)
    if not script_active or not source_prefix then return end
    if not scene_item then return end

    local crop = obs.obs_sceneitem_crop()
    crop.left = 0
    crop.right = 0
    crop.top = 0
    crop.bottom = 0
    obs.obs_sceneitem_set_crop(scene_item, crop)

    local position = obs.vec2()
    position.x = x + x_offset
    position.y = y + y_offset
    obs.obs_sceneitem_set_pos(scene_item, position)

    local scale = obs.vec2()
    scale.x = x_scale
    scale.y = y_scale
    obs.obs_sceneitem_set_scale(scene_item, scale)
end

function hide_browser(scene_item)
    if not script_active or not source_prefix then return end
    if not scene_item then return end

    local scale = obs.vec2()
    scale.x = 0
    scale.y = 0
    obs.obs_sceneitem_set_scale(scene_item, scale)

    local position = obs.vec2()
    position.x = -1
    position.y = -1
    obs.obs_sceneitem_set_pos(scene_item, position)
end

function refresh_browsers()
    if not script_active or not source_prefix then return end
    local scene = obs.obs_get_scene_by_name(scene_name)
    if not scene then
        obs.obs_scene_release(scene)
        return
    end

    local scene_items = obs.obs_scene_enum_items(scene)
    if not scene_items then
        obs.obs_scene_release(scene)
        return
    end

    local found_browsers = {}

    for _, scene_item in ipairs(scene_items) do
        local source = obs.obs_sceneitem_get_source(scene_item)
        local source_name = obs.obs_source_get_name(source)

        if string.match(source_name, "^" .. source_prefix) then
            if obs.obs_sceneitem_visible(scene_item) then
                found_browsers[source_name] = true
                if not browser_sources[source_name] then
                    browser_sources[source_name] = true
                end
            else
                if browser_sources[source_name] then
                    browser_sources[source_name] = nil
                end
            end
        end
    end

    for source_name in pairs(browser_sources) do
        if not found_browsers[source_name] then
            browser_sources[source_name] = nil
        end
    end

    obs.sceneitem_list_release(scene_items)
    obs.obs_scene_release(scene) 

    process_browsers()
end

function script_load(settings)
    language_name = obs.obs_data_get_string(settings, "language_name")
    scene_name = obs.obs_data_get_string(settings, "scene_name")
    source_prefix = obs.obs_data_get_string(settings, "source_prefix")
    temp_source_prefix = source_prefix
    spacing = obs.obs_data_get_int(settings, "spacing")
    margin = obs.obs_data_get_int(settings, "margin")
    x_offset = obs.obs_data_get_int(settings, "x_offset")
    y_offset = obs.obs_data_get_int(settings, "y_offset")
    obs.timer_add(refresh_browsers, interval)
    script_active = true
end

function script_unload()
    script_active = false
    obs.timer_remove(refresh_browsers)
end

function script_save(settings)
    obs.obs_data_set_string(settings, "language_name", language_name)
    obs.obs_data_set_string(settings, "scene_name", scene_name)
    obs.obs_data_set_string(settings, "source_prefix", source_prefix)
    obs.obs_data_set_int(settings, "spacing", spacing)
    obs.obs_data_set_int(settings, "margin", margin)
    obs.obs_data_set_int(settings, "x_offset", x_offset)
    obs.obs_data_set_int(settings, "y_offset", y_offset)
end

function on_language_changed(props, prop, settings)
    language_name = obs.obs_data_get_string(settings, "language_name")
    if language_name == "English" then
        for i, v in ipairs(en_US) do
            language[i] = v
        end
    elseif language_name == "Português" then
        for i, v in ipairs(pt_BR) do
            language[i] = v
        end
    elseif language_name == "Español" then
        for i, v in ipairs(es_ES) do
            language[i] = v
        end
    elseif language_name == "中文" then
        for i, v in ipairs(zh_CN) do
            language[i] = v
        end
    elseif language_name == "Русский" then
        for i, v in ipairs(ru_RU) do
            language[i] = v
        end
    elseif language_name == "日本語" then
        for i, v in ipairs(ja_JP) do
            language[i] = v
        end
    elseif language_name == "Deutsch" then
        for i, v in ipairs(de_DE) do
            language[i] = v
        end
    end

    return menu(props)
end

function on_scene_changed(props, prop, settings)
    scene_name = obs.obs_data_get_string(settings, "scene_name")
    refresh_browsers()
end

function on_source_prefix_changed(props, property, settings)
    local value = obs.obs_data_get_string(settings, "source_prefix")
    if value then
        temp_source_prefix = value
    end
end

function on_save_button_clicked(props, prop)
    if string.len(temp_source_prefix) > 0 then
        source_prefix = temp_source_prefix
    else
        source_prefix = false
    end
    refresh_browsers()
end

function on_spacing_changed(props, prop, settings)
    spacing = obs.obs_data_get_int(settings, "spacing")
    process_browsers()
end

function on_margin_changed(props, prop, settings)
    margin = obs.obs_data_get_int(settings, "margin")
    process_browsers()
end

function on_x_offset_changed(props, prop, settings)
    x_offset = obs.obs_data_get_int(settings, "x_offset")
    process_browsers()
end

function on_y_offset_changed(props, prop, settings)
    y_offset = obs.obs_data_get_int(settings, "y_offset")
    process_browsers()
end

function on_split_screen_changed(props, property, settings)
    split_screen = obs.obs_data_get_bool(settings, "split_screen")
    process_browsers()
end

function script_properties()
    local props = obs.obs_properties_create()
    return menu(props)
end

function menu(props)
    local language_list = obs.obs_properties_add_list(props, "language_name", language[1], obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)

    for i, v in ipairs(languages) do
        obs.obs_property_list_add_string(language_list, v, v)
    end
    obs.obs_property_set_modified_callback(language_list, on_language_changed)

    local scenes = obs.obs_frontend_get_scenes()
    local scene_list = obs.obs_properties_add_list(props, "scene_name", language[2], obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)

    for _, scene in ipairs(scenes) do
        local scene_name = obs.obs_source_get_name(scene)
        obs.obs_property_list_add_string(scene_list, scene_name, scene_name)
    end
    obs.obs_property_set_modified_callback(scene_list, on_scene_changed)

    local source_prefix_prop = obs.obs_properties_add_text(props, "source_prefix", language[3], obs.OBS_TEXT_DEFAULT)
    obs.obs_property_set_modified_callback(source_prefix_prop, on_source_prefix_changed)
    obs.obs_properties_add_button(props, "save_source_prefix", "✔", on_save_button_clicked)

    local spacing_prop = obs.obs_properties_add_int_slider(props, "spacing", language[4], 0, 100, 1)
    obs.obs_property_set_modified_callback(spacing_prop, on_spacing_changed)

    local margin_prop = obs.obs_properties_add_int_slider(props, "margin", language[5], 0, screen_height / 2, 1)
    obs.obs_property_set_modified_callback(margin_prop, on_margin_changed)

    local x_offset_prop = obs.obs_properties_add_int_slider(props, "x_offset", language[6], screen_width * -1, screen_width, 1)
    obs.obs_property_set_modified_callback(x_offset_prop, on_x_offset_changed)

    local y_offset_prop = obs.obs_properties_add_int_slider(props, "y_offset", language[7], screen_height * -1, screen_height, 1)
    obs.obs_property_set_modified_callback(y_offset_prop, on_y_offset_changed)

    local split_screen_checkbox = obs.obs_properties_add_bool(props, "split_screen", language[8])
    obs.obs_property_set_modified_callback(split_screen_checkbox, on_split_screen_changed)

    obs.source_list_release(scenes)
    return props
end
