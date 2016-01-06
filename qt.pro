# Create the super cache so modules will add themselves to it.
cache(, super)

CONFIG += build_pass   # hack to disable the .qmake.super auto-add
load(qt_build_config)
CONFIG -= build_pass   # unhack, as it confuses Qt Creator

TEMPLATE      = subdirs

defineReplace(moduleName) {
    return(module_$$replace(1, -, _))
}

# Arguments: module name, [mandatory deps], [optional deps], [project file]
defineTest(addModule) {
    for(d, $$list($$2 $$3)): \
        !contains(MODULES, $$d): \
            error("'$$1' depends on not (yet) declared '$$d'.")
    MODULES += $$1
    export(MODULES)

    contains(QT_SKIP_MODULES, $$1): return(false)
    !isEmpty(QT_BUILD_MODULES):!contains(QT_BUILD_MODULES, $$1): return(false)
    mod = $$moduleName($$1)

    isEmpty(4) {
        !exists($$1/$${1}.pro): return(false)
        $${mod}.subdir = $$1
        export($${mod}.subdir)
    } else {
        !exists($$1/$${4}): return(false)
        $${mod}.file = $$1/$$4
        $${mod}.makefile = Makefile
        export($${mod}.file)
        export($${mod}.makefile)
    }

    for(d, 2) {
        dn = $$moduleName($$d)
        !contains(SUBDIRS, $$dn): \
            return(false)
        $${mod}.depends += $$dn
    }
    for(d, 3) {
        dn = $$moduleName($$d)
        contains(SUBDIRS, $$dn): \
            $${mod}.depends += $$dn
    }
    !isEmpty($${mod}.depends): \
        export($${mod}.depends)

    $${mod}.target = module-$$1
    export($${mod}.target)

    SUBDIRS += $$mod
    export(SUBDIRS)
    return(true)
}

# only qtbase is required to exist. The others may not - but it is the
# users responsibility to ensure that all needed dependencies exist, or
# it may not build.

addModule(qtbase)
addModule(qtandroidextras, qtbase)
addModule(qtmacextras, qtbase)
addModule(qtx11extras, qtbase)
addModule(qtsvg, qtbase)
addModule(qtxmlpatterns, qtbase)
addModule(qtdeclarative, qtbase, qtsvg qtxmlpatterns)
addModule(qtgraphicaleffects, qtdeclarative)
addModule(qtquickcontrols, qtdeclarative, qtgraphicaleffects)
addModule(qtquickcontrols2, qtquickcontrols)
addModule(qtmultimedia, qtbase, qtdeclarative)
addModule(qtwinextras, qtbase, qtdeclarative qtmultimedia)
addModule(qtactiveqt, qtbase)
addModule(qtsystems, qtbase, qtdeclarative)
addModule(qtsensors, qtbase, qtdeclarative)
addModule(qtconnectivity, qtbase, qtdeclarative qtandroidextras)
addModule(qtfeedback, qtdeclarative, qtmultimedia)
addModule(qtpim, qtdeclarative)
addModule(qtwebsockets, qtbase, qtdeclarative)
addModule(qtwebchannel, qtbase, qtdeclarative qtwebsockets)
addModule(qtserialport, qtbase)
addModule(qtlocation, qtbase, qtdeclarative qtquickcontrols qtserialport qtsystems)
addModule(qtwebkit, qtbase, qtdeclarative qtlocation qtmultimedia qtsensors qtwebchannel qtxmlpatterns, WebKit.pro)
addModule(qttools, qtbase, qtdeclarative qtactiveqt qtwebkit)
addModule(qtwebkit-examples, qtwebkit qttools)
addModule(qtimageformats, qtbase)
addModule(qt3d, qtdeclarative qtimageformats)
addModule(qtcanvas3d, qtdeclarative)
addModule(qtscript, qtbase, qttools)
addModule(qtquick1, qtscript, qtsvg qtxmlpatterns)
addModule(qtdocgallery, qtdeclarative)
addModule(qtwayland, qtbase, qtdeclarative)
addModule(qtserialbus, qtserialport)
addModule(qtenginio, qtdeclarative)
addModule(qtwebengine, qtquickcontrols qtwebchannel, qtlocation)
addModule(qtwebview, qtdeclarative, qtwebengine)
addModule(qtpurchasing, qtbase, qtdeclarative)
addModule(qttranslations, qttools)
addModule(qtdoc, qtdeclarative)
addModule(qtqa, qtbase)
addModule(tqtc-qtdatavis3d, qtbase qtdeclarative, , qtdatavisualization.pro)
addModule(tqtc-qtcharts, qtbase qtdeclarative, , qtcharts.pro)
addModule(tqtc-scenegraph-raster, qtbase qtdeclarative, , scenegraph-raster.pro)
addModule(tqtc-qtvirtualkeyboard, qtbase qtdeclarative qtmultimedia qtquickcontrols qtsvg, , virtualkeyboard.pro)
addModule(tqtc-qmlcompiler, qtbase qtdeclarative, , qmlcompiler.pro)
