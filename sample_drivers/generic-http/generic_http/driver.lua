-- Copyright 2020 Wirepath Home Systems, LLC. All rights reserved.

JSON = require ('common.json')
common_lib = require ('common.common_lib')
common_timer = require ('common.common_timer')
common_url = require ('common.common_url')

function OnDriverLateInit ()
	if (not (Variables and Variables.HTTP_RESPONSE_DATA)) then
		C4:AddVariable ('HTTP_RESPONSE_DATA', '', 'STRING', true, false)
		C4:SetVariable ('HTTP_RESPONSE_DATA', '')
	end

	if (not (Variables and Variables.HTTP_RESPONSE_CODE)) then
		C4:AddVariable ('HTTP_RESPONSE_CODE', 0, 'NUMBER', true, false)
		C4:SetVariable ('HTTP_RESPONSE_CODE', 0)
	end

	if (not (Variables and Variables.HTTP_ERROR)) then
		C4:AddVariable ('HTTP_ERROR', '', 'STRING', true, false)
		C4:SetVariable ('HTTP_ERROR', '')
	end

	Presets = {}

	for property, _ in pairs (Properties) do
		OnPropertyChanged (property)
	end
end

function OnPropertyChanged (strProperty)
	local value = Properties [strProperty]
	if (value == nil) then
		value = ''
	end

	local presetNum = tonumber (string.match (strProperty, ('Preset URL (%d)')))

	if (strProperty == 'Debug Mode') then
		if (value == 'On') then
			dbg = print
		else
			dbg = function () end
		end

	elseif (strProperty == 'URL Timeout') then
		C4:urlSetTimeout (tonumber (value))

	elseif (presetNum) then
		Presets [presetNum] = value
	end
end

function ExecuteCommand (strCommand, tParams)
	tParams = tParams or {}

	local output = {'--- ExecuteCommand', strCommand, '----PARAMS----'}
	for k,v in pairs (tParams) do table.insert (output, tostring (k) .. ' = ' .. tostring (v)) end
	table.insert (output, '---')
	output = table.concat (output, '\r\n')
	dbg (output)

	if (strCommand == 'LUA_ACTION') then
		if (tParams.ACTION) then
			strCommand = tParams.ACTION
			tParams.ACTION = nil
		end
	end

	local preset = tonumber (tParams.PRESET)

	local url = (preset and Presets [preset]) or tParams.URL

	local headers = {
		['X-C4-DEMO-TIME'] = os.time (),
		['X-C4-SUPER-SECRET-API-KEY'] = 'hunter2',
	}

	if (url and url ~= '') then
		if (string.find (strCommand, 'GET')) then
			dbg ('Sending GET to ' .. url)
			urlGet (url, data, CheckResponse, contextInfo)

		elseif (string.find (strCommand, 'POST')) then
			local data = tParams.DATA or ''
			dbg ('Sending POST to ' .. url .. ' with data:/r/n' .. data)
			urlPost (url, data, headers, CheckResponse, contextInfo)
		end
	end
end

function CheckResponse (strError, responseCode, tHeaders, data, context, url)
	local output = {'---URL response---'}
	if (strError) then
		table.insert (output, strError)
	else
		table.insert (output, 'Response Code: ' .. tostring (responseCode))
		table.insert (output, 'Returned data: ' .. (data or ''))
	end
	output = table.concat (output, '\r\n')
	dbg (output)

	if (strError) then
		C4:SetVariable ('HTTP_ERROR', strError)
		C4:SetVariable ('HTTP_RESPONSE_DATA', '')
		C4:SetVariable ('HTTP_RESPONSE_CODE', 0)
		C4:FireEvent ('Error')
	else
		C4:SetVariable ('HTTP_ERROR', '')
		C4:SetVariable ('HTTP_RESPONSE_DATA', data)
		C4:SetVariable ('HTTP_RESPONSE_CODE', responseCode)
		C4:FireEvent ('Success')
	end
end
