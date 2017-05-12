using GL;
using Gtk;
using Pango;

public class Shady : Window
{
	private HeaderBar headerBar;
	private Image playIcon;
	private Image pauseIcon;
	private Button buttonRun;

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
		sourceView.show_line_numbers = true;
		sourceView.show_line_marks = true;
		sourceView.indent_on_tab = true;
		sourceView.auto_indent = true;
		sourceView.highlight_current_line = true;

		sourceView.override_font(FontDescription.from_string("Monospace"));

		scrolledSource = new ScrolledWindow(null, null);
		scrolledSource.set_size_request(400, 480);

		scrolledSource.add(sourceView);

		paned.pack2(scrolledSource, true, true);

		playIcon = new Image.from_icon_name("media-playback-start", IconSize.BUTTON);
		pauseIcon = new Image.from_icon_name("media-playback-pause", IconSize.BUTTON);

		buttonRun = new Button();
		buttonRun.set_image(playIcon);
		buttonRun.set_valign(Align.CENTER);

		buttonRun.clicked.connect(() => {
			if (shaderArea.paused)
			{
				shaderArea.paused = false;
				shaderArea.compile(sourceBuffer.text);
				shaderArea.queue_draw();

				buttonRun.set_image(pauseIcon);
			}
			else
			{
				shaderArea.paused = true;
				buttonRun.set_image(playIcon);
			}
		});

		headerBar = new HeaderBar();

		headerBar.set_title("Titel");
		headerBar.set_subtitle("Untertitel");

		headerBar.add(buttonRun);

		set_titlebar(headerBar);

		add(paned);
	}
	int foobar = 0;
}
