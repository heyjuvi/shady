using GL;
using Gtk;
using Gdk;
using Shady.Core;

namespace Shady
{
	public class ChannelArea : ShaderArea
	{
		/* Buffer properties structs*/
		private RenderResources.BufferProperties _target_prop = new RenderResources.BufferProperties();
		private CompileResources _compile_resources = new CompileResources();

		/* Shader render buffer variables */

		private Mutex _size_mutex = Mutex();

		public ChannelArea()
		{
			realize.connect(() =>
			{
				init_gl(get_default_shader());
			});

			resize.connect((width, height) =>
			{
				update_size(width, height);
			});

			render.connect(() =>
			{
				_size_mutex.lock();
				update_uniform_values();
				render_gl(_target_prop);
				_size_mutex.unlock();
				queue_draw();
				return false;
			});
		}

		public static Shader? get_shader_from_input(Shader.Input input)
		{
			Shader.Renderpass input_renderpass = get_renderpass_from_input(input);

			Shader input_shader = new Shader();
			input_shader.renderpasses.append_val(input_renderpass);

			return input_shader;
		}

		public static Shader.Renderpass? get_renderpass_from_input(Shader.Input input)
		{
			Shader.Renderpass input_renderpass = new Shader.Renderpass();
			input_renderpass.inputs.append_val(input);
			input_renderpass.type = Shader.RenderpassType.IMAGE;

			/*
			if (input.resource == null)
			{
				print("Input has no specified resource!\n");
				return null;
			}
			*/

			try
			{
				if (input.type == Shader.InputType.TEXTURE)
				{
					input_renderpass.code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/texture_channel_default.glsl", 0).get_data());
				}
				else if (input.type == Shader.InputType.CUBEMAP)
				{
					input_renderpass.code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/cubemap_channel_default.glsl", 0).get_data());
				}
				else if (input.type == Shader.InputType.3DTEXTURE)
				{
					input_renderpass.code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/3dtexture_channel_default.glsl", 0).get_data());
				}
				else if (input.type == Shader.InputType.NONE)
				{
					input_renderpass.code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/none_channel_default.glsl", 0).get_data());
				}
			}
			catch(Error e)
			{
				print("Couldn't load default shader for input type!\n");
				return null;
			}

			return input_renderpass;
		}

		public void compile_shader_input(Shader.Input input)
		{
			if(input.resource!=null){
				_target_prop.context.make_current();

				int width = 0;
				int height = 0;
				int depth = 0;
				int channel;

				GLuint tex_target;

				Shader.Input input_copy = new Shader.Input();
				input_copy.assign(input);
				input_copy.channel=0;

				ShaderCompiler.init_sampler(input_copy, _target_prop.sampler_ids[0]);

				if(input.type == Shader.InputType.BUFFER){
					input_copy.type = Shader.InputType.TEXTURE;
					input_copy.resource_index = 22 + input_copy.id - 3;
					input_copy.sampler.v_flip = true;
				}

				GLuint[] tex_ids = TextureManager.query_input_texture(input_copy, (uint64) get_window(), ref width, ref height, ref depth, out tex_target);

				if(tex_ids != null && tex_ids.length > 0){

					Shader? input_shader = get_shader_from_input(input_copy);

					string full_target_source = SourceGenerator.generate_renderpass_source(input_shader.renderpasses.index(0), false);

					_target_prop.context = get_context();
					ShaderCompiler.compile_pass(-1, full_target_source, _target_prop, _compile_resources);

					_target_prop.tex_ids[0] = tex_ids[0];
					_target_prop.tex_targets[0] = tex_target;

					channel = input_copy.channel;

					_target_prop.tex_channels[0] = channel;

					if(channel>=0 && channel<4){
						_target_prop.tex_widths[channel] = width;
						_target_prop.tex_heights[channel] = height;
						_target_prop.tex_depths[channel] = depth;
					}
				}
			}
		}

		private void init_gl(Shader default_shader)
		{
			make_current();

			GLuint[] tex_arr = {0};
			glGenTextures(1, tex_arr);

			glBindTexture(GL_TEXTURE_2D, tex_arr[0]);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

			ShaderCompiler.init_compile_resources(_compile_resources);

			init_target_pass(_target_prop, _compile_resources, tex_arr[0]);

			init_time();

			Gdk.GLContext.clear_current();
		}

		private void render_gl(RenderResources.BufferProperties buf_prop)
		{
			buf_prop.context.make_current();

			glViewport(0, 0, _width, _height);

			glUseProgram(buf_prop.program);

			set_uniform_values(buf_prop);

			glBindVertexArray(buf_prop.vao);

			glDrawArrays(GL_TRIANGLES, 0, 3);

			glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
		}
	}
}
