using GL;
using Gtk;

public class Shady : Window
{
	private HeaderBar headerBar;
	private Paned paned;

	private ShaderArea shaderArea;

	private ScrolledWindow scrolledSource;
	private SourceView sourceView;
	private SourceBuffer sourceBuffer;
	private SourceLanguage sourceLanguage;
	private SourceLanguageManager sourceLanguageManager;

	public Shady()
	{
		paned = new Paned(Orientation.HORIZONTAL);

		shaderArea = new ShaderArea();
		shaderArea.set_size_request(400, 480);

		paned.pack1(shaderArea, true, true);

		sourceLanguageManager = SourceLanguageManager.get_default();;

		sourceLanguage = sourceLanguageManager.get_language("glsl");

		sourceBuffer = new SourceBuffer.with_language(sourceLanguage);

		sourceView = new SourceView.with_buffer(sourceBuffer);
		sourceView.set_show_line_numbers(true);
		sourceView.set_show_line_marks(true);
		sourceView.set_indent_on_tab(true);
		sourceView.set_auto_indent(true);

		scrolledSource = new ScrolledWindow(null, null);
		scrolledSource.set_size_request(400, 480);

		scrolledSource.add(sourceView);

		paned.pack2(scrolledSource, true, true);

		headerBar = new HeaderBar();
		headerBar.set_title("Titel");
		headerBar.set_subtitle("Untertitel");

		set_titlebar(headerBar);

		add(paned);
	}
}
