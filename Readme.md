## Dust Ultimate Game Library (DUGL)
Is an x86-32bits cross-platform C Game library using software rasterizer.
**DUGL** is developed on top of **SDL** (https://www.libsdl.org/) as wrapper for most OS operation as graphic initialization, inputs (Keyboard/Mouse...), Outputs (Sound..), Synchronization (Time), Processing (Multi-Thread..) ...

Using heavily a highly optimized x86-32bits assembly to render to 16bits screen, limits its usage for game development or software’s that do not require accurate colours. 16bpp was picked as the best balance between performance and nice looking final render result.

### Target platform ###

Theoretically, any platform that **SDL** is able to target and which support running x86-32bits with **SSE4.2+**  (either emulated or real hardware)

### History ###

Started on 1999 as a **DOS** (https://en.wikipedia.org/wiki/DOS) game library, using **DJGPP** (https://delorie.com/djgpp/) as gcc C/C++ compiler and **NASM** (https://nasm.us/) as the assembly compiler and targeting Intel **MMX+** CPU and DOS compatible OS and VESA 2.0 for graphic initialization.

On 2020, I decided to port it to be over **SDL** to allow it to go cross-platform and decided to target higher CPU architecture (**SSE4.2+**).

### Features ###

**DUGL** has some of the fastest graphic rendering routines around. Written entirely in x86 assembly, some of the routines (as Poly16) has crossed over 200 optimization cycles that allowed them to use most of the available memory bandwidth for rendering. Additionally, the use of 16bpp instead of 32bits RGBA allow at least a boost of 100% in number of pixels rendered per second and half the CPU cache requirement for the rendered screen.

* **Primary render functions**: 
  1. Polygones (Solid, Textured, Masked Textured, Textured Colour Blended, Masked Textured Colour Blended, Transparent Textured, Masked Transparent Textured..).
  2. Lines (Solid, mapped, Transparent, Transparent mapped).
  3. Sprites/Images blitting (without resize, but capability to reverse horizontally and vertically, could be Masked, Colour Blended or Transparent)
  4. Images Resize blitting (same as sprites, allow reversing horizontally or vertically but resize source View to Destination View to avoid clipping handling and get the best performance)
  5. Blur filter adapted to 16bpp to reduce the darkening or getting greener over blurring cycles
  6. Proprietary simple Font format ...
* **View System**:
Implement an ascending Y Axis, with origin at default at bottom/left Corner. Allow to change origin and rendering bounds with zero cost in performance.
* **Keyboard/Mouse Handling**:
Implement a layer over **SDL** allowing a custom keyboard/mouse and events queue handling. 
* **Timer**: Time synchronising functions.
* **Sound**: Sound module with up to 64 mixed channels, with looping, pause, queue and volume.
* **Images**: Implement image loader functions from file or memory supporting (**GIF**(8bits not interlaced ), **BMP**(8/16Bits not compressed), PCX(8Bits), **JPEG**(using libjpeg or libjpeg-Turbo), **PNG** (using libpng and zlib)
* **Threading**: Implement **DMutex** and **DWorker** concept, a simple/flexible layer over **SDL** Threading functions, allowing to allocate sleeping threads (threads pool) and change dynamically their function/data/priority.
* **Container**: Chained Chunks memory allocator, Fast Dictionnary (char\*,void\*), String separator(s) splitter, Threaded(DWorker) File Buffering.
* **Math3D**: Support Matrix4x4, VEC4 and VEC2 (float or integer) implements a wide range of functions impelmented in SIMD assembly.

### Building ###
#####  Under Windows: #####
Requirement:

- **CodeBlocks IDE** (https://www.codeblocks.org)
- **MinGW** Recommended version 8.1+  (currently using http://winlibs.com - gcc-9.4.0-mingw-w64-9.0.0-r2 32bits standalone)
- **Nasm** Recommended the latest stable 2.15.05 (https://nasm.us/)
- **LibSDL** use the latest SDL2-devel-xxx-mingw.tar.gz from website (https://libsdl.org)
- **LibJpeg**, **LibPNG** and **ZLib** better download sources of each lib and compile with your current **MinGW** distribution for best compatibility.

Compiling asm sources:

**CodeBlocks** do not support compiling asm source files using nasm by default. 
You need to (1) Go to **Global compilers Settings** => **Other settings** => **Advanced options..** (2) Add two new **Source ext** "asm" and "ASM" (3) Select the **Command** "Compile single file to object file" and (4) set the **Command line macro:** to "nasm $file -f win32 -Ox -o $object"


### Contact ###

Please feel free to email the author(s) - libdugl@hotmail.com





 
