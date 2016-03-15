all: shady

shady: Makefile program.vala shady.vala shader_area.vala
	valac -o shady --vapidir=vapi --pkg gtk+-3.0 --pkg gtksourceview-3.0 --pkg gl --pkg epoxy program.vala shady.vala shader_area.vala

clean:
	rm -f shady
