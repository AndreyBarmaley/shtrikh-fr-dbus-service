#!/bin/bash

dbus-send --system --print-reply --type=method_call \
	--dest=ru.shtrih_m.fr.kassa1 /ru/shtrih_m/fr/kassa1/object ru.shtrih_m.fr.kassa1.interface.device_get_status int32:30
