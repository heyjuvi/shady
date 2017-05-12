using GL;
using Gtk;

public errordomain ShaderError {
	COMPILATION
}

public class ShaderArea : GLArea
{
	private GLuint program;
	private GLuint fragmentShader;
	private GLuint[] vao={1337};
	private GLint time_loc;
	private GLint res_loc;
	private int64 start_time;
	private int64 curr_time;
	private int64 pause_time;

	private bool initialized;

	public bool paused { get; set; default = false; }

	public ShaderArea(string fragmentSource)
	{
		this.initialized = false;

		this.realize.connect(() => {
			this.make_current();
	
			if (this.get_error() != null)
			{
				return;
			}
	
			const string vertexSource="attribute vec2 vertex;void main(void) {gl_Position = vec4(vertex,1,1);}";
	
			const string[] vertexSourceArray = { vertexSource, null };
	
			GLuint vertexShader=glCreateShader(GL_VERTEX_SHADER);
			glShaderSource(vertexShader,1,vertexSourceArray,null);
			glCompileShader(vertexShader);
	
			fragmentShader=glCreateShader(GL_FRAGMENT_SHADER);
	
			program = glCreateProgram();

			glAttachShader(program, vertexShader);
			glAttachShader(program, fragmentShader);

			compile(fragmentSource);

			glGenVertexArrays (1, vao);
			glBindVertexArray (vao[0]);
	
			GLuint[] vbo = {1337};
			glGenBuffers(1, vbo);
	
			GLfloat[] vertices = {  1,  1, 
			                       -1,  1, 
			                       -1, -1, 
			                        1, -1};
	
			glBindBuffer (GL_ARRAY_BUFFER, vbo[0]);
			glBufferData (GL_ARRAY_BUFFER, vertices.length * sizeof (GLfloat), (GLvoid[]) vertices, GL_STATIC_DRAW);
	
			GLuint attrib=glGetAttribLocation (program, "vertex");
	
			glEnableVertexAttribArray (attrib);
			glVertexAttribPointer (attrib, 2, GL_FLOAT, (GLboolean)GL_FALSE, 0, null);
	
			time_loc = glGetUniformLocation (program, "iGlobalTime");
			res_loc = glGetUniformLocation (program, "iResolution");
	
			glBindBuffer (GL_ARRAY_BUFFER, 0);
			glBindVertexArray (0);

			glDeleteBuffers(1,vbo);

			start_time=get_monotonic_time();

			initialized = true;
		});
		//this.size_allocate.connect(render_gl);
		this.render.connect(on_render);
	}

	private bool on_render()
	{
		this.render_gl();
		this.queue_draw();

		return true;
	}

	public void render_gl()
	{
		if (this.initialized)
		{
			glClearColor(0, 0, 0, 1);
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

			int width=this.get_allocated_width();
			int height=this.get_allocated_height();

			glViewport(0, 0, width, height);

			glUseProgram(program);

			float time;

			if(!paused){
				curr_time=get_monotonic_time();
				time = (curr_time - start_time) / 1000000.0f;
			}
			else{
				time = (pause_time - start_time) / 1000000.0f;
			}

			glUniform1f(time_loc, time);
			glUniform3f(res_loc, width, height, 0);

			glBindVertexArray (vao[0]);

			glDrawArrays(GL_TRIANGLE_FAN,0,4);

			glBindVertexArray (0);
			glUseProgram (0);

			glFlush();
		}
	}

	public void compile(string shaderSource) throws ShaderError {

			string shaderPrefix="uniform vec3 iResolution;uniform float iGlobalTime;";
			string shaderSuffix="void main(void){vec4 col;mainImage(col,gl_FragCoord.xy);gl_FragColor=col;}";

			string fullShaderSource=shaderPrefix+shaderSource+shaderSuffix;
			string[] sourceArray = { fullShaderSource, null };

			glShaderSource(fragmentShader,1,sourceArray,null);
			glCompileShader(fragmentShader);

			GLint success[] = {0};
			glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, success);

			if(success[0]== GL_FALSE){
				GLint logSize[] = {0};
				glGetShaderiv(fragmentShader, GL_INFO_LOG_LENGTH, logSize);
				GLubyte[] log = new GLubyte[logSize[0]];
				glGetShaderInfoLog(fragmentShader, logSize[0], logSize, log);
				throw new ShaderError.COMPILATION((string)log);
			}

			glLinkProgram(program);
	}

	public void pause(bool pause_status){
		paused=pause_status;
		if(pause_status==true){
			pause_time=get_monotonic_time();
		}
		else{
			start_time+=get_monotonic_time() - pause_time;
		}
	}

	public void reset_time(){
		start_time=curr_time;
	}
}
