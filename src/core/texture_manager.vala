using GL;

namespace Shady.Core
{
	public class TextureManager
	{

		public TextureManager()
		{
		}

		struct TextureBufferUnit
		{
			public Shader.InputType type;
			public int index;
			public bool v_flip;
			public int input_id;
			public GLuint[] tex_ids;
			public GLuint target;
			public int width;
			public int height;
			public int depth;
			public uint64 window_id;
		}

		private static GLib.Once<TextureManager> _buffer;

		public static unowned TextureManager buffer()
		{
			return _buffer.once(() =>
			{
				return new TextureManager();	
			});
		}

		private static TextureBufferUnit[] _texture_buffer = {};
		private static TextureBufferUnit[] _buffer_buffer = {};

		public static GLuint[] query_input_texture(Shader.Input input, uint64 window, ref int width, ref int height, ref int depth, out uint target)
		{
			target = -1;

			int i;

			if(input.type == Shader.InputType.BUFFER)
			{
				for(i=0;i<_buffer_buffer.length;i++)
				{
				    if(_buffer_buffer[i].type == Shader.InputType.BUFFER &&
					   _buffer_buffer[i].input_id == input.id &&
					   _buffer_buffer[i].window_id == window)
					{
						width = _buffer_buffer[i].width;
						height = _buffer_buffer[i].height;
						depth = _buffer_buffer[i].depth;
						target = _buffer_buffer[i].target;
						return _buffer_buffer[i].tex_ids;
					}
				}
				if(i == _buffer_buffer.length)
				{
					GLuint[] tex_ids = init_input_texture(input, ref width, ref height, ref depth, out target);
					TextureBufferUnit tex_unit = TextureBufferUnit()
					{
						width = width,
						height = height,
						depth = depth,
						target = target,
						input_id = input.id,
						tex_ids = tex_ids,
						type = input.type,
						v_flip = input.sampler.v_flip,
						index = i,
						window_id = window
					};

					_buffer_buffer += tex_unit;
					return tex_ids;
				}
			}
			else
			{
				for(i=0;i<_texture_buffer.length;i++)
				{
					if(input.type == _texture_buffer[i].type &&
					   _texture_buffer[i].index == input.resource_index &&
					   _texture_buffer[i].v_flip == input.sampler.v_flip &&
					   _texture_buffer[i].window_id == window)
					{
						width = _texture_buffer[i].width;
						height = _texture_buffer[i].height;
						depth = _texture_buffer[i].depth;
						target = _texture_buffer[i].target;
						return _texture_buffer[i].tex_ids;
					}
				}
				if(i == _texture_buffer.length)
				{
					GLuint[] tex_ids = init_input_texture(input, ref width, ref height, ref depth, out target);
					TextureBufferUnit tex_unit = TextureBufferUnit()
					{
						width = width,
						height = height,
						depth = depth,
						target = target,
						input_id = input.id,
						tex_ids = tex_ids,
						type = input.type,
						v_flip = input.sampler.v_flip,
						index = input.resource_index,
						window_id = window
					};

					_texture_buffer += tex_unit;
					return tex_ids;
				}
			}
			return {};
		}

		public static GLuint[] query_output_texture(Shader.Output? output, uint64 window, int width, int height)
		{
			if(output != null)
			{
				int i;
				for(i=0;i<_buffer_buffer.length;i++)
				{
					if(_buffer_buffer[i].type == Shader.InputType.BUFFER &&
					   _buffer_buffer[i].input_id == output.id &&
					   _buffer_buffer[i].window_id == window)
					{
						return _buffer_buffer[i].tex_ids;
					}
				}

				if(i == _buffer_buffer.length)
				{
					Shader.Input input = new Shader.Input();
					input.id = output.id;
					input.type = Shader.InputType.BUFFER;

					int depth = 0;
					uint target;

					GLuint[] tex_ids = init_input_texture(input, ref width, ref height, ref depth, out target);
					TextureBufferUnit tex_unit = TextureBufferUnit()
					{
						width = width,
						height = height,
						depth = depth,
						target = target,
						input_id = input.id,
						tex_ids = tex_ids,
						type = input.type,
						v_flip = input.sampler.v_flip,
						index = i,
						window_id = window
					};

					_buffer_buffer += tex_unit;
					return tex_ids;
				}
			}
			else //image buffer
			{
				Shader.Input input = new Shader.Input();
				input.id = -1;
				input.type = Shader.InputType.BUFFER;

				int depth = 0;
				uint target;

				return init_input_texture(input, ref width, ref height, ref depth, out target);
			}
			return {};
		}

		private static GLuint[] init_input_texture(Shader.Input input, ref int width, ref int height, ref int depth, out uint target)
		{
			target = -1;

			GLuint[] tex_ids = {};

			if(input.type == Shader.InputType.TEXTURE)
			{
				if(!(input.resource_index < ShadertoyResourceManager.TEXTURE_IDS.length))
				{
					input.resource_index = 0;
				}

				target = GL_TEXTURE_2D;
				tex_ids = {0};
				glGenTextures(1,tex_ids);
				glBindTexture(target, tex_ids[0]);

				glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
				glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);

				Gdk.Pixbuf buf = ShadertoyResourceManager.TEXTURE_PIXBUFS[input.resource_index];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}

				width = buf.get_width();
				height = buf.get_height();

				int format=-1;
				if(buf.get_n_channels() == 3)
				{
					format = GL_RGB;
				}
				else if(buf.get_n_channels() == 4)
				{
					format = GL_RGBA;
				}

				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());

				glGenerateMipmap(target);
			}
			else if(input.type == Shader.InputType.3DTEXTURE)
			{
				if(!(input.resource_index < ShadertoyResourceManager.3DTEXTURE_IDS.length))
				{
					input.resource_index = 0;
				}

				target = GL_TEXTURE_3D;
				tex_ids = {0};
				glGenTextures(1,tex_ids);
				glBindTexture(target, tex_ids[0]);

				glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
				glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);

				ShadertoyResourceManager.Voxmap voxmap = ShadertoyResourceManager.3DTEXTURE_VOXMAPS[input.resource_index];

				width = voxmap.width;
				height = voxmap.height;
				depth = voxmap.depth;

				int format=-1;
				if (voxmap.n_channels == 1)
				{
					format = GL_RED;
				}
				else if (voxmap.n_channels == 3)
				{
					format = GL_RGB;
				}
				else if (voxmap.n_channels == 4)
				{
					format = GL_RGBA;
				}

				glTexImage3D(GL_TEXTURE_3D, 0, format, width, height, depth, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])voxmap.voxels);
				glGenerateMipmap(target);
			}
			else if(input.type == Shader.InputType.CUBEMAP)
			{
				if(!(input.resource_index < ShadertoyResourceManager.CUBEMAP_IDS.length))
				{
					input.resource_index = 0;
				}

				target = GL_TEXTURE_CUBE_MAP;
				tex_ids = {0};
				glGenTextures(1,tex_ids);
				glBindTexture(target, tex_ids[0]);

				glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
				glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);

				Gdk.Pixbuf buf = ShadertoyResourceManager.CUBEMAP_PIXBUFS_ARRAY[input.resource_index,0];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}

				width = buf.get_width();
				height = buf.get_height();

				int format=-1;
				if(buf.get_n_channels() == 3)
				{
					format = GL_RGB;
				}
				else if(buf.get_n_channels() == 4)
				{
					format = GL_RGBA;
				}

				glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());
				buf = ShadertoyResourceManager.CUBEMAP_PIXBUFS_ARRAY[input.resource_index,1];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}

				glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());
				buf = ShadertoyResourceManager.CUBEMAP_PIXBUFS_ARRAY[input.resource_index,2];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}


				glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());
				buf = ShadertoyResourceManager.CUBEMAP_PIXBUFS_ARRAY[input.resource_index,3];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}

				glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());
				buf = ShadertoyResourceManager.CUBEMAP_PIXBUFS_ARRAY[input.resource_index,4];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}


				glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());
				buf = ShadertoyResourceManager.CUBEMAP_PIXBUFS_ARRAY[input.resource_index,5];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}

				glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());
				glGenerateMipmap(target);
			}
			else if(input.type == Shader.InputType.BUFFER)
			{
				target = GL_TEXTURE_2D;
				tex_ids = {0, 0};
				glGenTextures(2,tex_ids);

				for(int i=0;i<2;i++)
				{
					glBindTexture(target, tex_ids[i]);
					glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

					glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
					glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);

					glGenerateMipmap(GL_TEXTURE_2D);
				}
			}
			else if(input.type == Shader.InputType.NONE)
			{
				target = GL_TEXTURE_2D;
				tex_ids = {0};
				glGenTextures(1,tex_ids);

				//glBindTexture(target, tex_ids[0]);
				//glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

				//glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
				//glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
			}
			else{
				print("Unexpected input type\n");
			}

			return tex_ids;
		}
	}
}
