using GL;
using Gtk;
using Pango;

public class Shady : Window
{
	private HeaderBar headerBar;
	private Image resetIcon;
	private Image playIcon;
	private Image pauseIcon;
	private Image compileIcon;
	private Button buttonReset;
	private Button buttonRun;
	private Button buttonCompile;

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

		string defaultShader="void mainImage( out vec4 fragColor, in vec2 fragCoord )\n{\n\tvec2 uv = fragCoord.xy / iResolution.xy;\n\tfragColor = vec4(uv,0.5+0.5*sin(iGlobalTime),1.0);\n}";

		shaderArea = new ShaderArea(defaultShader);
		shaderArea.set_size_request(400, 480);

		paned.pack1(shaderArea, true, true);

		sourceLanguageManager = SourceLanguageManager.get_default();;

		sourceLanguage = sourceLanguageManager.get_language("glsl");

		sourceBuffer = new SourceBuffer.with_language(sourceLanguage);

		sourceBuffer.text=defaultShader;

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

		resetIcon = new Image.from_icon_name("media-skip-backward", IconSize.BUTTON);
		playIcon = new Image.from_icon_name("media-playback-start", IconSize.BUTTON);
		pauseIcon = new Image.from_icon_name("media-playback-pause", IconSize.BUTTON);
		compileIcon = new Image.from_icon_name("media-playback-start", IconSize.BUTTON);

		buttonReset = new Button();
		buttonReset.set_image(resetIcon);
		buttonReset.set_valign(Align.CENTER);
		buttonReset.set_halign(Align.START);

		buttonRun = new Button();
		buttonRun.set_image(pauseIcon);
		buttonRun.set_valign(Align.CENTER);
		buttonRun.set_halign(Align.START);

		buttonCompile = new Button();
		buttonCompile.set_image(compileIcon);
		buttonCompile.set_valign(Align.CENTER);
		buttonCompile.set_halign(Align.END);

		buttonReset.clicked.connect(() => {
			shaderArea.reset_time();
		});

		buttonRun.clicked.connect(() => {
			if (shaderArea.paused)
			{
				shaderArea.pause(false);

				buttonRun.set_image(pauseIcon);
			}
			else
			{
				shaderArea.pause(true);
				buttonRun.set_image(playIcon);
			}
		});

		buttonCompile.clicked.connect(() => {
			shaderArea.compile(sourceBuffer.text);
		});

		headerBar = new HeaderBar();

		headerBar.set_title("Shady");

		headerBar.add(buttonReset);
		headerBar.add(buttonRun);
		headerBar.add(buttonCompile);

		set_titlebar(headerBar);

		add(paned);
	}
}
