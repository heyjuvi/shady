[CCode (cheader_filename = "glslang/Public/ShaderLang.h")]
namespace GLSlang
{
	[CCode (cname = "EShMessages", has_type_id = false, cprefix = "EShMsg")]
	public enum Messages
	{
		Default,
		RelaxedErrors,
		SuppressWarnings,
		AST,
		gSpvRules,
		VulkanRules,
		OnlyPreprocessor,
		ReadHlsl,
		CascadingErrors,
		KeepUncalled,
		HlslOffsets,
		DebugInfo
	}
}

