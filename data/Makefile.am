-include $(top_srcdir)/git.mk

gsettings_SCHEMAS = org.hasi.shady.gschema.xml
@GSETTINGS_RULES@

gschemas.compiled: Makefile $(gsettings_SCHEMAS:.xml=.valid)
	$(AM_V_GEN) $(GLIB_COMPILE_SCHEMAS) --targetdir=$(builddir) $(builddir)

EXTRA_DIST = \
	org.hasi.shady.gschema.xml

CLEANFILES = \
	gschemas.compiled \
	org.hasi.shady.gschema.valid

all-local: gschemas.compiled
