echo "Packaging"

echo "Assets [1/4]"
rm -rf build/
mkdir -p "build"
echo "Assets [2/4]"
cp -R assets/ build/
echo "Assets [3/4]"


# Remove unused files
# FIXME: make this better
rm -rf build/assets/shaders
rm -rf build/assets/textures
echo "Assets [4/4]"

echo "Compiling just incase"
ext/build.sh 2> /dev/null && echo "Done compiling, packaging."
cp dementia build/ 2> /dev/null
cp kurarin build/ 2> /dev/null
