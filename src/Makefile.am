bin_PROGRAMS = shady

WARN_CFLAGS += \
	-Wno-error=discarded-qualifiers \
	-Wno-error=unused-variable \
	-Wno-error=unused-but-set-variable \
	-Wno-error=deprecated-declarations \
	-Wno-error=incompatible-pointer-types \
	-Wno-error=pointer-sign \
	-Wno-error=unused-function \
	$(NULL)

shady_SOURCES = \
	shady.gresource.c \
	main.vala \
	io_sugar.vala \
	app.vala \
	app_window.vala \
	app_preferences.vala \
	gl_context.vala \
	shader_area.vala \
	shadertoy_search_dialog.vala \
	shadertoy_shader_item.vala

shady_CPPFLAGS = -g -O0 $(WARN_CFLAGS) $(SHADY_CFLAGS)
shady_VALAFLAGS = \
	--pkg epoxy \
	--pkg gl \
	--pkg egl \
	--pkg gtksourceview-3.0 \
	--pkg gtk+-3.0 \
	--pkg libsoup-2.4 \
	--pkg json-glib-1.0 \
	--target-glib=2.38 \
	--vapidir=vapi \
	--gresources $(top_srcdir)/shady.gresource.xml

shady_LDADD = $(SHADY_LIBS) -lepoxy -lX11

gresource_file = $(top_srcdir)/shady.gresource.xml
shady.gresource.c: $(gresource_file)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) \
		--target=$@ \
		--sourcedir=$(top_srcdir)/ \
		--generate-source $<

CLEANFILES = \
	shady.gresource.c \
	$(imagetool_SOURCES:.vala=.c) \
	*.stamp \
	$(NULL)

-include $(top_srcdir)/git.mk
