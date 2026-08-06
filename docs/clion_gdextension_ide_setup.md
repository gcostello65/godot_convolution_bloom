CLion
CLion is a commercial JetBrains IDE for C++.

Importing the project
CLion can import a project's compilation database file, commonly named compile_commands.json. To generate the compilation database file, open the terminal, change to the Godot root directory, and run:

scons compiledb=yes
Then, open the Godot root directory with CLion. CLion will import the compilation database, index the codebase, and provide autocompletion and other advanced code navigation and refactoring functionality.

Compiling and debugging the project
CLion does not support compiling and debugging Godot via SCons out of the box. This can be achieved by creating a custom build target and run configuration in CLion. Before creating a custom build target, you must compile Godot once on the command line, to generate the Godot executable. Open the terminal, change into the Godot root directory, and execute:

scons dev_build=yes
To add a custom build target that invokes SCons for compilation:

Open CLion and navigate to Preferences > Build, Execution, Deployment > Custom Build Targets

../../../_images/clion-preferences.png
Click Add target and give the target a name, e.g. Godot debug.

../../../_images/clion-target.png
Click ... next to the Build: selectbox, then click the + button in the External Tools dialog to add a new external tool.

../../../_images/clion-external-tools.png
Give the tool a name, e.g. Build Godot debug, set Program to scons, set Arguments to the compilation settings you want (see compiling Godot), and set the Working directory to $ProjectFileDir$, which equals the Godot root directory. Click OK to create the tool.

Note

CLion does not expand shell commands like scons -j$(nproc). Use concrete values instead, e.g. scons -j8.

../../../_images/clion-create-build-tool.webp
Back in the External Tools dialog, click the + again to add a second external tool for cleaning the Godot build via SCons. Give the tool a name, e.g. Clean Godot debug, set Program to scons, set Arguments to -c (which will clean the build), and set the Working directory to $ProjectFileDir$. Click OK to create the tool.

../../../_images/clion-create-clean-tool.png
Close the External Tools dialog. In the Custom Build Target dialog for the custom Godot debug build target, select the Build Godot debug tool from the Build select box, and select the Clean Godot debug tool from the Clean select box. Click OK to create the custom build target.

../../../_images/clion-select-tools.png
In the main IDE window, click Add Configuration.

../../../_images/clion-add-configuration.png
In the Run/Debug Configuration dialog, click Add new..., then select Custom Build Application to create a new custom run/debug configuration.

../../../_images/clion-add-custom-build-application.png
Give the run/debug configuration a name, e.g. Godot debug, select the Godot debug custom build target as the Target. Select the Godot executable in the bin/ folder as the Executable, and set the Program arguments to --editor --path path-to-your-project/, where path-to-your-project/ should be a path pointing to an existing Godot project. If you omit the --path argument, you will only be able to debug the Godot Project Manager window. Click OK to create the run/debug configuration.

../../../_images/clion-run-configuration.png
You can now build, run, debug, profile, and Valgrind check the Godot editor via the run configuration.

../../../_images/clion-build-run.png
When playing a scene, the Godot editor will spawn a separate process. You can debug this process in CLion by going to Run > Attach to process..., typing godot, and selecting the Godot process with the highest pid (process ID), which will usually be the running project.

Ignoring object and library files
After building Godot in CLion, you may see the object and library files showing up in the Project view.

../../../_images/clion-object-library-files-in-project-view.webp
You can configure CLion to ignore those files:

Open CLion and navigate to Preferences > Editor > File Types > Ignored Files and Folders

Click the + button to add *.o and *.a to the list. In Windows, you would add *.obj and *.dll.

../../../_images/clion-ignore-object-library-files.webp
Now, the files should be ignored in the Project view.


