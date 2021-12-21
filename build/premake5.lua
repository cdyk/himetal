solution "HiMetal"
	configurations { "Debug", "Release" }

project "HiMetal"
	kind "WindowedApp"
	language "C++"
	cppdialect "c++17"
	targetdir "%{cfg.buildcfg}"

	files {
		"premake5.lua",
        "../source/**.h",
		"../source/**.m",
		"../source/**.cpp",
        "../data/**.metal"
	}

	sysincludedirs {
		"../libs/metal-cpp"
	}

	links {
		"Cocoa.framework",
        "Metal.framework",
        "MetalKit.framework"
	}

    filter "files:**.metal"
        buildaction "Resource"

	filter "configurations:Debug"
		defines { "DEBUG" }
		symbols "On"

	filter "configurations:Release"
		defines { "NDEBUG" }
		symbols "On"
		optimize "On"
