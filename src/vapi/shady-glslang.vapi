[CCode (cheader_filename = "glslang/glslang.h")]
namespace GLSlang
{
    [CCode (cheader_filename = "glslang/glslang.h", cname = "glslang_initialize")]
    public static bool initialize();

    [CCode (cheader_filename = "glslang/glslang.h", cname = "glslang_finalize")]
    public static void finalize();

    [CCode (cheader_filename = "glslang/glslang.h", cname = "glslang_validate")]
    public static bool validate(string shader_source, int version = 110, out string? info_log = null, out string? info_debug_log = null);
}

