bin_PROGRAMS = shady

shady_SOURCES = \
	shady.gresource.c \
	main.vala \
	io_sugar.vala \
	app.vala \
	app_window.vala \
	shader_area.vala

shady_CPPFLAGS = $(SHADY_CFLAGS)
shady_VALAFLAGS = \
	--pkg epoxy \
	--pkg gl \
	--pkg gtksourceview-3.0 \
	--pkg gtk+-3.0 \
	--target-glib=2.38 \
	--vapidir=vapi \
	--gresources $(top_srcdir)/shady.gresource.xml

shady_LDADD = $(SHADY_LIBS) -lepoxy

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
