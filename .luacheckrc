-- luacheck: no global
self = false
include_files = { "src/**/*.lua" }
globals = {
	_G = {
		other_fields = true,
		oUF_Adirelle = { read_only = false, other_fields = true },
	},
}
