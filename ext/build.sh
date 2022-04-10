build_shaders() {
    v shader assets/shaders/slider.glsl
}

build_debug() {
    clear &&
    echo "Build: Debug" &&
    build_shaders &&
    v -cc gcc -cg .
}

build_development() {
    clear &&
    echo "Build: Development" &&
    build_shaders &&
    v -cc gcc -gc boehm .
}

build_production() {
    clear &&
    echo "Build: Production" &&
    build_shaders &&
    v -cc gcc -gc boehm -prod .
}

case $1 in 
    "--prod"|"--production"|"-prod")
        build_production
        exit 0
        ;;

    "--debug"|"--debug"|"-debug")
        build_debug
        exit 0
        ;;
    *)
    
    # devel build?
    build_development

esac
