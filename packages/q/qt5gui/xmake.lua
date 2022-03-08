package("qt5gui")
    set_homepage("https://www.qt.io")
    set_description("Qt is the faster, smarter way to create innovative devices, modern UIs & applications for multiple screens. Cross-platform software development at its best.")
    set_license("LGPL-3")

    add_configs("shared", {description = "Download shared binaries.", default = true, type = "boolean", readonly = true})
    add_configs("vs_runtime", {description = "Set vs compiler runtime.", default = "MD", readonly = true})

    add_versions("5.15.2", "dummy")
    add_versions("5.12.5", "dummy")

    on_load(function (package)
        package:add("deps", "qt5base", "qt5core", {debug = package:is_debug(), version = package:version_str()})
    end)

    on_fetch(function (package)
        local qt = package:dep("qt5base"):data("qt")
        if not qt then
            return
        end

        local linkname
        local syslinks
        local frameworks
        local includedirs = {qt.includedir}
        if package:is_plat("windows") then
            linkname = "Qt5Gui"
            if package:is_debug() then
                linkname = linkname .. "d"
            end
            table.insert(includedirs, path.join(qt.includedir, "QtGui"))
        elseif package:is_plat("android") then
            linkname = "Qt5Gui"
            if package:is_arch("x86_64", "x64") then
                linkname = linkname .. "_x86_64"
            elseif package:is_arch("arm64", "arm64-v8a") then
                linkname = linkname .. "_arm64-v8a"
            elseif package:is_arch("armv7", "armeabi-v7a", "armeabi", "armv7-a", "armv5te") then
                linkname = linkname .. "_armeabi-v7a"
            elseif package:is_arch("x86") then
                linkname = linkname .. "_x86"
            end
            syslinks = "GLESv2"
            table.insert(includedirs, path.join(qt.includedir, "QtGui"))
        elseif package:is_plat("macosx") then
            table.insert(includedirs, path.join(qt.libdir, "QtGui.framework/Versions/5/Headers"))
            frameworks = "QtGui"
        elseif package:is_plat("iphoneos") then
            linkname = {"Qt5Gui", "qtharfbuzz"}
            syslinks = {"qtlibpng", "z"}
            table.insert(includedirs, path.join(qt.includedir, "QtGui"))
        else
            linkname = "Qt5Gui"
            table.insert(includedirs, path.join(qt.includedir, "QtGui"))
        end

        return {
            qtdir = qt,
            version = qt.version,
            includedirs = includedirs,
            links = linkname,
            linkdirs = qt.libdir,
            frameworks = frameworks,
            frameworkdirs = qt.libdir,
            syslinks = syslinks
        }
    end)

    on_install("windows", "linux", "macosx", "mingw", "android", "iphoneos", function (package)
        local qt = package:dep("qt5base"):data("qt")
        assert(qt, "qt5base is required")
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            int test(int argc, char** argv) {
                QGuiApplication app (argc, argv);
                return app.exec();
            }
        ]]}, {configs = {languages = "c++14", cxflags = not package:is_plat("windows") and "-fPIC" or nil}, includes = {"QGuiApplication"}}))
    end)