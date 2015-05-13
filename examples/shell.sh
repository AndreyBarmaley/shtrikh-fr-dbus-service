#!/bin/bash

dbus-send --system --print-reply --type=method_call \
	--dest=ru.shtrih_m.fr /ru/shtrih_m/fr/object ru.shtrih_m.fr.interface.device_get_status int32:30
