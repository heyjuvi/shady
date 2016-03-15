using GL;
using Gtk;

public class ShaderArea : GLArea
{
	private GLuint program;
	private GLuint[] vao={1337};
	private GLint time_loc;
	private GLint res_loc;
	private int64 start_time;
	private int64 curr_time;

	public ShaderArea()
	{
		this.realize.connect(() => {
			this.make_current();
	
			if (this.get_error() != null)
			{
				return;
			}
	
			const string vertexSource="attribute vec2 vertex;void main(void) {gl_Position = vec4(vertex,1,1);}";
			const string fragmentSource="uniform vec3 iResolution; uniform float iGlobalTime; void main(void){ gl_FragColor=vec4(10.*length(vec2(iGlobalTime*-.1,-.25) + gl_FragCoord.xy/iResolution.x),1,1,1);}";
	
			const string[] vertexSourceArray = { vertexSource, null };
			const string[] fragmentSourceArray = { fragmentSource, null };
	
			GLuint vertexShader=glCreateShader(GL_VERTEX_SHADER);
			glShaderSource(vertexShader,1,vertexSourceArray,null);
			glCompileShader(vertexShader);
	
			GLuint fragmentShader=glCreateShader(GL_FRAGMENT_SHADER);
			glShaderSource(fragmentShader,1,fragmentSourceArray,null);
			glCompileShader(fragmentShader);
	
			program = glCreateProgram();
			glAttachShader(program, vertexShader);
			glAttachShader(program, fragmentShader);
			glLinkProgram(program);
	
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

			//glDeleteBuffers(1,vbo);
			start_time=get_monotonic_time();
		});
		this.render.connect(on_render);
	}

	private bool on_render()
	{
		glClearColor(0, 0, 0, 1);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		int width=this.get_allocated_width();
		int height=this.get_allocated_height();

		glViewport(0, 0, width, height);

		glUseProgram(program);

		curr_time=get_monotonic_time();
		float time = (curr_time - start_time) / 1000000.0f;

		glUniform1f(time_loc, time);
		glUniform3f(res_loc, width, height, 0);

		glBindVertexArray (vao[0]);

		//glFrontFace(GL_CW);

		glDrawArrays(GL_TRIANGLE_FAN,0,4);
		//glDrawArrays(GL_TRIANGLES,0,3);

		glBindVertexArray (0);
		glUseProgram (0);

		glFlush();

		this.queue_draw();

		return true;
	}
}
