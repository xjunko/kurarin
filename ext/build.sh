build_shaders() {
    v shader assets/shaders/slider.glsl
}

build_debug() {
    clear &&
    echo "Build: Debug w/o GC" &&
    build_shaders &&
    v -cc gcc -cg .
}

build_debug_gc() {
    clear &&
    echo "Build: Debug w/ GC" &&
    build_shaders &&
    v -cc gcc -gc boehm -cg .
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

run_program() {
    echo "Running Program!" &&
    ./dementia
}

# Build type
case $1 in 
    "--prod"|"--production"|"-prod")
        build_production
        ;;

    "--debug"|"--debug"|"-debug")
        build_debug_gc
        ;;

    "--debug_raw"|"-debug_raw")
        build_debug
        ;;
    *)
    
    # Nothing passed, devel build
    build_development
esac

# TODO: not familiar with bash, make this better.
case $1 in 
    "--run"|"-run")
        run_program
        ;;

    *)
esac

case $2 in 
    "--run"|"-run")
        run_program
        ;;

    *)
esac
