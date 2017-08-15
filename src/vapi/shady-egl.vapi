namespace EGL {
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLBoolean")]
	[SimpleType]
	public struct EGLBoolean : uint8 {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLint")]
	[SimpleType]
	public struct EGLint : uint32 {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLDisplay")]
	[SimpleType]
	public struct EGLDisplay {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLConfig")]
	[SimpleType]
	public struct EGLConfig {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLSurface")]
	[SimpleType]
	public struct EGLSurface {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLContext")]
	[SimpleType]
	public struct EGLContext {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLenum")]
	[SimpleType]
	public struct EGLenum : uint {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLClientBuffer")]
	[SimpleType]
	public struct EGLClientBuffer {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLSync")]
	[SimpleType]
	public struct EGLSync {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLAttrib")]
	[SimpleType]
	public struct EGLAttrib {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLTime")]
	[SimpleType]
	public struct EGLTime : uint64 {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLImage")]
	[SimpleType]
	public struct EGLImage {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "__eglMustCastToProperFunctionPointerType")]
	[SimpleType]
	public struct __eglMustCastToProperFunctionPointerType {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLNativeDisplayType")]
	[SimpleType]
	public struct EGLNativeDisplayType : int {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLNativePixmapType")]
	[SimpleType]
	public struct EGLNativePixmapType {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGLNativeWindowType")]
	[SimpleType]
	public struct EGLNativeWindowType {
	}
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VERSION_1_0")]
	public const int EGL_VERSION_1_0;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_ALPHA_SIZE")]
	public const int EGL_ALPHA_SIZE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BAD_ACCESS")]
	public const int EGL_BAD_ACCESS;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BAD_ALLOC")]
	public const int EGL_BAD_ALLOC;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BAD_ATTRIBUTE")]
	public const int EGL_BAD_ATTRIBUTE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BAD_CONFIG")]
	public const int EGL_BAD_CONFIG;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BAD_CONTEXT")]
	public const int EGL_BAD_CONTEXT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BAD_CURRENT_SURFACE")]
	public const int EGL_BAD_CURRENT_SURFACE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BAD_DISPLAY")]
	public const int EGL_BAD_DISPLAY;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BAD_MATCH")]
	public const int EGL_BAD_MATCH;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BAD_NATIVE_PIXMAP")]
	public const int EGL_BAD_NATIVE_PIXMAP;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BAD_NATIVE_WINDOW")]
	public const int EGL_BAD_NATIVE_WINDOW;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BAD_PARAMETER")]
	public const int EGL_BAD_PARAMETER;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BAD_SURFACE")]
	public const int EGL_BAD_SURFACE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BLUE_SIZE")]
	public const int EGL_BLUE_SIZE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BUFFER_SIZE")]
	public const int EGL_BUFFER_SIZE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONFIG_CAVEAT")]
	public const int EGL_CONFIG_CAVEAT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONFIG_ID")]
	public const int EGL_CONFIG_ID;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CORE_NATIVE_ENGINE")]
	public const int EGL_CORE_NATIVE_ENGINE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_DEPTH_SIZE")]
	public const int EGL_DEPTH_SIZE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_DONT_CARE")]
	public const int EGL_DONT_CARE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_DRAW")]
	public const int EGL_DRAW;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_EXTENSIONS")]
	public const int EGL_EXTENSIONS;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_FALSE")]
	public const int EGL_FALSE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GREEN_SIZE")]
	public const int EGL_GREEN_SIZE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_HEIGHT")]
	public const int EGL_HEIGHT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_LARGEST_PBUFFER")]
	public const int EGL_LARGEST_PBUFFER;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_LEVEL")]
	public const int EGL_LEVEL;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_MAX_PBUFFER_HEIGHT")]
	public const int EGL_MAX_PBUFFER_HEIGHT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_MAX_PBUFFER_PIXELS")]
	public const int EGL_MAX_PBUFFER_PIXELS;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_MAX_PBUFFER_WIDTH")]
	public const int EGL_MAX_PBUFFER_WIDTH;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NATIVE_RENDERABLE")]
	public const int EGL_NATIVE_RENDERABLE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NATIVE_VISUAL_ID")]
	public const int EGL_NATIVE_VISUAL_ID;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NATIVE_VISUAL_TYPE")]
	public const int EGL_NATIVE_VISUAL_TYPE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NONE")]
	public const int EGL_NONE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NON_CONFORMANT_CONFIG")]
	public const int EGL_NON_CONFORMANT_CONFIG;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NOT_INITIALIZED")]
	public const int EGL_NOT_INITIALIZED;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NO_CONTEXT")]
	public const int EGL_NO_CONTEXT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NO_DISPLAY")]
	public const int EGL_NO_DISPLAY;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NO_SURFACE")]
	public const int EGL_NO_SURFACE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_PBUFFER_BIT")]
	public const int EGL_PBUFFER_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_PIXMAP_BIT")]
	public const int EGL_PIXMAP_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_READ")]
	public const int EGL_READ;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_RED_SIZE")]
	public const int EGL_RED_SIZE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SAMPLES")]
	public const int EGL_SAMPLES;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SAMPLE_BUFFERS")]
	public const int EGL_SAMPLE_BUFFERS;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SLOW_CONFIG")]
	public const int EGL_SLOW_CONFIG;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_STENCIL_SIZE")]
	public const int EGL_STENCIL_SIZE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SUCCESS")]
	public const int EGL_SUCCESS;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SURFACE_TYPE")]
	public const int EGL_SURFACE_TYPE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_TRANSPARENT_BLUE_VALUE")]
	public const int EGL_TRANSPARENT_BLUE_VALUE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_TRANSPARENT_GREEN_VALUE")]
	public const int EGL_TRANSPARENT_GREEN_VALUE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_TRANSPARENT_RED_VALUE")]
	public const int EGL_TRANSPARENT_RED_VALUE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_TRANSPARENT_RGB")]
	public const int EGL_TRANSPARENT_RGB;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_TRANSPARENT_TYPE")]
	public const int EGL_TRANSPARENT_TYPE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_TRUE")]
	public const int EGL_TRUE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VENDOR")]
	public const int EGL_VENDOR;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VERSION")]
	public const int EGL_VERSION;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_WIDTH")]
	public const int EGL_WIDTH;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_WINDOW_BIT")]
	public const int EGL_WINDOW_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VERSION_1_1")]
	public const int EGL_VERSION_1_1;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BACK_BUFFER")]
	public const int EGL_BACK_BUFFER;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BIND_TO_TEXTURE_RGB")]
	public const int EGL_BIND_TO_TEXTURE_RGB;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BIND_TO_TEXTURE_RGBA")]
	public const int EGL_BIND_TO_TEXTURE_RGBA;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONTEXT_LOST")]
	public const int EGL_CONTEXT_LOST;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_MIN_SWAP_INTERVAL")]
	public const int EGL_MIN_SWAP_INTERVAL;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_MAX_SWAP_INTERVAL")]
	public const int EGL_MAX_SWAP_INTERVAL;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_MIPMAP_TEXTURE")]
	public const int EGL_MIPMAP_TEXTURE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_MIPMAP_LEVEL")]
	public const int EGL_MIPMAP_LEVEL;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NO_TEXTURE")]
	public const int EGL_NO_TEXTURE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_TEXTURE_2D")]
	public const int EGL_TEXTURE_2D;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_TEXTURE_FORMAT")]
	public const int EGL_TEXTURE_FORMAT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_TEXTURE_RGB")]
	public const int EGL_TEXTURE_RGB;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_TEXTURE_RGBA")]
	public const int EGL_TEXTURE_RGBA;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_TEXTURE_TARGET")]
	public const int EGL_TEXTURE_TARGET;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VERSION_1_2")]
	public const int EGL_VERSION_1_2;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_ALPHA_FORMAT")]
	public const int EGL_ALPHA_FORMAT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_ALPHA_FORMAT_NONPRE")]
	public const int EGL_ALPHA_FORMAT_NONPRE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_ALPHA_FORMAT_PRE")]
	public const int EGL_ALPHA_FORMAT_PRE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_ALPHA_MASK_SIZE")]
	public const int EGL_ALPHA_MASK_SIZE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BUFFER_PRESERVED")]
	public const int EGL_BUFFER_PRESERVED;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_BUFFER_DESTROYED")]
	public const int EGL_BUFFER_DESTROYED;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CLIENT_APIS")]
	public const int EGL_CLIENT_APIS;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_COLORSPACE")]
	public const int EGL_COLORSPACE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_COLORSPACE_sRGB")]
	public const int EGL_COLORSPACE_sRGB;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_COLORSPACE_LINEAR")]
	public const int EGL_COLORSPACE_LINEAR;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_COLOR_BUFFER_TYPE")]
	public const int EGL_COLOR_BUFFER_TYPE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONTEXT_CLIENT_TYPE")]
	public const int EGL_CONTEXT_CLIENT_TYPE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_DISPLAY_SCALING")]
	public const int EGL_DISPLAY_SCALING;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_HORIZONTAL_RESOLUTION")]
	public const int EGL_HORIZONTAL_RESOLUTION;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_LUMINANCE_BUFFER")]
	public const int EGL_LUMINANCE_BUFFER;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_LUMINANCE_SIZE")]
	public const int EGL_LUMINANCE_SIZE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_OPENGL_ES_BIT")]
	public const int EGL_OPENGL_ES_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_OPENVG_BIT")]
	public const int EGL_OPENVG_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_OPENGL_ES_API")]
	public const int EGL_OPENGL_ES_API;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_OPENVG_API")]
	public const int EGL_OPENVG_API;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_OPENVG_IMAGE")]
	public const int EGL_OPENVG_IMAGE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_PIXEL_ASPECT_RATIO")]
	public const int EGL_PIXEL_ASPECT_RATIO;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_RENDERABLE_TYPE")]
	public const int EGL_RENDERABLE_TYPE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_RENDER_BUFFER")]
	public const int EGL_RENDER_BUFFER;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_RGB_BUFFER")]
	public const int EGL_RGB_BUFFER;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SINGLE_BUFFER")]
	public const int EGL_SINGLE_BUFFER;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SWAP_BEHAVIOR")]
	public const int EGL_SWAP_BEHAVIOR;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_UNKNOWN")]
	public const int EGL_UNKNOWN;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VERTICAL_RESOLUTION")]
	public const int EGL_VERTICAL_RESOLUTION;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VERSION_1_3")]
	public const int EGL_VERSION_1_3;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONFORMANT")]
	public const int EGL_CONFORMANT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONTEXT_CLIENT_VERSION")]
	public const int EGL_CONTEXT_CLIENT_VERSION;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_MATCH_NATIVE_PIXMAP")]
	public const int EGL_MATCH_NATIVE_PIXMAP;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_OPENGL_ES2_BIT")]
	public const int EGL_OPENGL_ES2_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VG_ALPHA_FORMAT")]
	public const int EGL_VG_ALPHA_FORMAT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VG_ALPHA_FORMAT_NONPRE")]
	public const int EGL_VG_ALPHA_FORMAT_NONPRE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VG_ALPHA_FORMAT_PRE")]
	public const int EGL_VG_ALPHA_FORMAT_PRE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VG_ALPHA_FORMAT_PRE_BIT")]
	public const int EGL_VG_ALPHA_FORMAT_PRE_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VG_COLORSPACE")]
	public const int EGL_VG_COLORSPACE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VG_COLORSPACE_sRGB")]
	public const int EGL_VG_COLORSPACE_sRGB;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VG_COLORSPACE_LINEAR")]
	public const int EGL_VG_COLORSPACE_LINEAR;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VG_COLORSPACE_LINEAR_BIT")]
	public const int EGL_VG_COLORSPACE_LINEAR_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VERSION_1_4")]
	public const int EGL_VERSION_1_4;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_DEFAULT_DISPLAY")]
	public const int EGL_DEFAULT_DISPLAY;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_MULTISAMPLE_RESOLVE_BOX_BIT")]
	public const int EGL_MULTISAMPLE_RESOLVE_BOX_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_MULTISAMPLE_RESOLVE")]
	public const int EGL_MULTISAMPLE_RESOLVE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_MULTISAMPLE_RESOLVE_DEFAULT")]
	public const int EGL_MULTISAMPLE_RESOLVE_DEFAULT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_MULTISAMPLE_RESOLVE_BOX")]
	public const int EGL_MULTISAMPLE_RESOLVE_BOX;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_OPENGL_API")]
	public const int EGL_OPENGL_API;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_OPENGL_BIT")]
	public const int EGL_OPENGL_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SWAP_BEHAVIOR_PRESERVED_BIT")]
	public const int EGL_SWAP_BEHAVIOR_PRESERVED_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_VERSION_1_5")]
	public const int EGL_VERSION_1_5;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONTEXT_MAJOR_VERSION")]
	public const int EGL_CONTEXT_MAJOR_VERSION;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONTEXT_MINOR_VERSION")]
	public const int EGL_CONTEXT_MINOR_VERSION;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONTEXT_OPENGL_PROFILE_MASK")]
	public const int EGL_CONTEXT_OPENGL_PROFILE_MASK;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY")]
	public const int EGL_CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NO_RESET_NOTIFICATION")]
	public const int EGL_NO_RESET_NOTIFICATION;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_LOSE_CONTEXT_ON_RESET")]
	public const int EGL_LOSE_CONTEXT_ON_RESET;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT")]
	public const int EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT")]
	public const int EGL_CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONTEXT_OPENGL_DEBUG")]
	public const int EGL_CONTEXT_OPENGL_DEBUG;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONTEXT_OPENGL_FORWARD_COMPATIBLE")]
	public const int EGL_CONTEXT_OPENGL_FORWARD_COMPATIBLE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONTEXT_OPENGL_ROBUST_ACCESS")]
	public const int EGL_CONTEXT_OPENGL_ROBUST_ACCESS;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_OPENGL_ES3_BIT")]
	public const int EGL_OPENGL_ES3_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CL_EVENT_HANDLE")]
	public const int EGL_CL_EVENT_HANDLE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SYNC_CL_EVENT")]
	public const int EGL_SYNC_CL_EVENT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SYNC_CL_EVENT_COMPLETE")]
	public const int EGL_SYNC_CL_EVENT_COMPLETE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SYNC_PRIOR_COMMANDS_COMPLETE")]
	public const int EGL_SYNC_PRIOR_COMMANDS_COMPLETE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SYNC_TYPE")]
	public const int EGL_SYNC_TYPE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SYNC_STATUS")]
	public const int EGL_SYNC_STATUS;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SYNC_CONDITION")]
	public const int EGL_SYNC_CONDITION;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SIGNALED")]
	public const int EGL_SIGNALED;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_UNSIGNALED")]
	public const int EGL_UNSIGNALED;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SYNC_FLUSH_COMMANDS_BIT")]
	public const int EGL_SYNC_FLUSH_COMMANDS_BIT;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_FOREVER")]
	public const int EGL_FOREVER;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_TIMEOUT_EXPIRED")]
	public const int EGL_TIMEOUT_EXPIRED;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_CONDITION_SATISFIED")]
	public const int EGL_CONDITION_SATISFIED;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NO_SYNC")]
	public const int EGL_NO_SYNC;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_SYNC_FENCE")]
	public const int EGL_SYNC_FENCE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_COLORSPACE")]
	public const int EGL_GL_COLORSPACE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_COLORSPACE_SRGB")]
	public const int EGL_GL_COLORSPACE_SRGB;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_COLORSPACE_LINEAR")]
	public const int EGL_GL_COLORSPACE_LINEAR;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_RENDERBUFFER")]
	public const int EGL_GL_RENDERBUFFER;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_TEXTURE_2D")]
	public const int EGL_GL_TEXTURE_2D;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_TEXTURE_LEVEL")]
	public const int EGL_GL_TEXTURE_LEVEL;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_TEXTURE_3D")]
	public const int EGL_GL_TEXTURE_3D;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_TEXTURE_ZOFFSET")]
	public const int EGL_GL_TEXTURE_ZOFFSET;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_X")]
	public const int EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_X;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_X")]
	public const int EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_X;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_Y")]
	public const int EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_Y;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_Y")]
	public const int EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_Y;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_Z")]
	public const int EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_Z;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_Z")]
	public const int EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_Z;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_IMAGE_PRESERVED")]
	public const int EGL_IMAGE_PRESERVED;
	[CCode (cheader_filename = "EGL/egl.h", cname = "EGL_NO_IMAGE")]
	public const int EGL_NO_IMAGE;
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglChooseConfig")]
	public static EGL.EGLBoolean eglChooseConfig (EGL.EGLDisplay dpy, [CCode (array_length = false)] EGL.EGLint[] attrib_list, [CCode (array_length = false)] EGL.EGLConfig[]? configs, EGL.EGLint config_size, out EGL.EGLint num_config);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglCopyBuffers")]
	public static EGL.EGLBoolean eglCopyBuffers (EGL.EGLDisplay dpy, EGL.EGLSurface surface, EGL.EGLNativePixmapType target);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglCreateContext")]
	public static EGL.EGLContext eglCreateContext (EGL.EGLDisplay dpy, EGL.EGLConfig config, EGL.EGLContext share_context, [CCode (array_length = false)] EGL.EGLint[]? attrib_list);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglCreatePbufferSurface")]
	public static EGL.EGLSurface eglCreatePbufferSurface (EGL.EGLDisplay dpy, EGL.EGLConfig config, [CCode (array_length = false)] EGL.EGLint[] attrib_list);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglCreatePixmapSurface")]
	public static EGL.EGLSurface eglCreatePixmapSurface (EGL.EGLDisplay dpy, EGL.EGLConfig config, EGL.EGLNativePixmapType pixmap, [CCode (array_length = false)] EGL.EGLint[] attrib_list);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglCreateWindowSurface")]
	public static EGL.EGLSurface eglCreateWindowSurface (EGL.EGLDisplay dpy, EGL.EGLConfig config, EGL.EGLNativeWindowType win, [CCode (array_length = false)] EGL.EGLint[] attrib_list);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglDestroyContext")]
	public static EGL.EGLBoolean eglDestroyContext (EGL.EGLDisplay dpy, EGL.EGLContext ctx);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglDestroySurface")]
	public static EGL.EGLBoolean eglDestroySurface (EGL.EGLDisplay dpy, EGL.EGLSurface surface);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglGetConfigAttrib")]
	public static EGL.EGLBoolean eglGetConfigAttrib (EGL.EGLDisplay dpy, EGL.EGLConfig config, EGL.EGLint attribute, EGL.EGLint *value);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglGetConfigs")]
	public static EGL.EGLBoolean eglGetConfigs (EGL.EGLDisplay dpy, EGL.EGLConfig *configs, EGL.EGLint config_size, EGL.EGLint *num_config);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglGetCurrentDisplay")]
	public static EGL.EGLDisplay eglGetCurrentDisplay ();
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglGetCurrentSurface")]
	public static EGL.EGLSurface eglGetCurrentSurface (EGL.EGLint readdraw);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglGetDisplay")]
	public static EGL.EGLDisplay eglGetDisplay (EGL.EGLNativeDisplayType display_id);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglGetError")]
	public static EGL.EGLint eglGetError ();
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglMustCastToProperFunctionPointerType")]
	public static __eglMustCastToProperFunctionPointerType eglGetProcAddress (string procname);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglInitialize")]
	public static EGL.EGLBoolean eglInitialize (EGL.EGLDisplay dpy, EGL.EGLint *major, EGL.EGLint *minor);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglMakeCurrent")]
	public static EGL.EGLBoolean eglMakeCurrent (EGL.EGLDisplay dpy, EGL.EGLSurface draw, EGL.EGLSurface read, EGL.EGLContext ctx);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglQueryContext")]
	public static EGL.EGLBoolean eglQueryContext (EGL.EGLDisplay dpy, EGL.EGLContext ctx, EGL.EGLint attribute, EGL.EGLint *value);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglQueryString")]
	public static char * eglQueryString (EGL.EGLDisplay dpy, EGL.EGLint name);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglQuerySurface")]
	public static EGL.EGLBoolean eglQuerySurface (EGL.EGLDisplay dpy, EGL.EGLSurface surface, EGL.EGLint attribute, EGL.EGLint *value);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglSwapBuffers")]
	public static EGL.EGLBoolean eglSwapBuffers (EGL.EGLDisplay dpy, EGL.EGLSurface surface);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglTerminate")]
	public static EGL.EGLBoolean eglTerminate (EGL.EGLDisplay dpy);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglWaitGL")]
	public static EGL.EGLBoolean eglWaitGL ();
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglWaitNative")]
	public static EGL.EGLBoolean eglWaitNative (EGL.EGLint engine);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglBindTexImage")]
	public static EGL.EGLBoolean eglBindTexImage (EGL.EGLDisplay dpy, EGL.EGLSurface surface, EGL.EGLint buffer);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglReleaseTexImage")]
	public static EGL.EGLBoolean eglReleaseTexImage (EGL.EGLDisplay dpy, EGL.EGLSurface surface, EGL.EGLint buffer);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglSurfaceAttrib")]
	public static EGL.EGLBoolean eglSurfaceAttrib (EGL.EGLDisplay dpy, EGL.EGLSurface surface, EGL.EGLint attribute, EGL.EGLint value);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglSwapInterval")]
	public static EGL.EGLBoolean eglSwapInterval (EGL.EGLDisplay dpy, EGL.EGLint interval);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglBindAPI")]
	public static EGL.EGLBoolean eglBindAPI (EGL.EGLenum api);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglQueryAPI")]
	public static EGL.EGLenum eglQueryAPI ();
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglCreatePbufferFromClientBuffer")]
	public static EGL.EGLSurface eglCreatePbufferFromClientBuffer (EGL.EGLDisplay dpy, EGL.EGLenum buftype, EGL.EGLClientBuffer buffer, EGL.EGLConfig config, [CCode (array_length = false)] EGL.EGLint[] attrib_list);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglReleaseThread")]
	public static EGL.EGLBoolean eglReleaseThread ();
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglWaitClient")]
	public static EGL.EGLBoolean eglWaitClient ();
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglGetCurrentContext")]
	public static EGL.EGLContext eglGetCurrentContext ();
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglCreateSync")]
	public static EGL.EGLSync eglCreateSync (EGL.EGLDisplay dpy, EGL.EGLenum type, [CCode (array_length = false)] EGL.EGLAttrib[] attrib_list);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglDestroySync")]
	public static EGL.EGLBoolean eglDestroySync (EGL.EGLDisplay dpy, EGL.EGLSync sync);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglClientWaitSync")]
	public static EGL.EGLint eglClientWaitSync (EGL.EGLDisplay dpy, EGL.EGLSync sync, EGL.EGLint flags, EGL.EGLTime timeout);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglGetSyncAttrib")]
	public static EGL.EGLBoolean eglGetSyncAttrib (EGL.EGLDisplay dpy, EGL.EGLSync sync, EGL.EGLint attribute, EGL.EGLAttrib *value);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglCreateImage")]
	public static EGL.EGLImage eglCreateImage (EGL.EGLDisplay dpy, EGL.EGLContext ctx, EGL.EGLenum target, EGL.EGLClientBuffer buffer, [CCode (array_length = false)] EGL.EGLAttrib[] attrib_list);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglDestroyImage")]
	public static EGL.EGLBoolean eglDestroyImage (EGL.EGLDisplay dpy, EGL.EGLImage image);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglGetPlatformDisplay")]
	public static EGL.EGLDisplay eglGetPlatformDisplay (EGL.EGLenum platform, void *native_display, [CCode (array_length = false)] EGL.EGLAttrib[] attrib_list);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglCreatePlatformWindowSurface")]
	public static EGL.EGLSurface eglCreatePlatformWindowSurface (EGL.EGLDisplay dpy, EGL.EGLConfig config, void *native_window, [CCode (array_length = false)] EGL.EGLAttrib[]  attrib_list);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglCreatePlatformPixmapSurface")]
	public static EGL.EGLSurface eglCreatePlatformPixmapSurface (EGL.EGLDisplay dpy, EGL.EGLConfig config, void *native_pixmap, [CCode (array_length = false)] EGL.EGLAttrib[] attrib_list);
	[CCode (cheader_filename = "EGL/egl.h", cname = "eglWaitSync")]
	public static EGL.EGLBoolean eglWaitSync (EGL.EGLDisplay dpy, EGL.EGLSync sync, EGL.EGLint flags);
}
