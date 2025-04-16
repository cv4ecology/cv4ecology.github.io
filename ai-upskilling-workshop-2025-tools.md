# Recommended software installation for 2025 AI upskilling workshop

There are no strict requirements for the software tools participants use during the workshop, but especially if you are new to Python, your experience will likely be better if you use the same tools the instructors are using.  Consequently, we strongly recommend that participants - especially the "new to Python" group - install the following tools prior to the workshop.  For VS Code in particular, we recommend following our installation instructions, so that your environment is as similar as possible to the environment that the instructors and other participants are using.

* [Visual Studio Code](https://code.visualstudio.com/) (the development environment we'll use to edit and run Python code) ([#installing-and-exploring-visual-studio-code](installation instructions))
* [Miniforge](https://github.com/conda-forge/miniforge) (the command-line tool we'll use to manage Python environments and packages) (([#installing-miniforge](installation instructions))
* Any SSH client you're comfortable with; if you don't have a preferred SSH client, we recommend [PortX](https://portx.online/en/)


## Installing and exploring Visual Studio Code

We will generally refer to "Visual Studio Code" as "VS Code".


### Downloading and installing VS Code

* Install VS code from [code.visualstudio.com](https://code.visualstudio.com/)


### Setting up Python support in VS Code

* Click on this icon on the left to bring up the extensions menu, or press ctrl-shift-x:

  <img src="images/tools_vscode_extensions_thumb.jpg">
  
* Search for "Python" in the extensions menu, and install the Python extension, which looks like this:

  <img src="images/tools_python_extension.jpg">
  
* Search for "Jupyter" in the extensions menu, and install the Jupyter extension, which looks like this:

  <img src="images/tools_jupyter_extension.jpg">


### Download or create a test Python file

If you want to get a feel for what VS Code looks like, it's helpful to have a Python file available that's in the same "style" that we'll be recommending during the workshop, especially for the new-to-Python group.  In particular, we will be using lines that look like this:

`#%%`

To separate "cells" in our code.  A cell is a small block of code (typically 10-50 lines) that does something you can describe in a few words; you often want to make changes to a cell, then re-run the whole cell.  This is something that will be familiar to Matlab users, but is less common in Python code.  VS Code will allow you to execute a cell of code as an atomic action, so this ends up being a very convenient way to break up your code.  Typically you would give a cell a name, like this:

`#%% Load the data file`

Because cells are important to the visual experience you'll have in VS Code, and are important to the way you'll run code, as you get used to VS Code, we recommend having a Python file open with a few cells in it.  We put a file [here]() that doesn't do anything useful, but has the "look and feel" of the code you'll see during the workshop.  You may want to download that file and open it in VS Code (using file &rarr; open) as you customize and explore VS Code.


### Editing and running Python code

Any time you want to run an entire Python file from VS Code, you can click "run &arr; debug" or "run &arr; start without debugging".  But you won't do this very often; when working on data science and machine learning code, it's more common to run small bits of code at a time as you build up your Python program.  In VS Code, we will be using the [Python Interactive Window](https://code.visualstudio.com/docs/python/jupyter-support-py) for this.  Think of this window like a live copy of the state of your program, where you can keep running new code and changing variables.  This style of running code will be familiar to Matlab and R users.

Once you've 

### VS Code customizations that may make Matlab/R users feel more at home

<b>None of these tweaks are required</b>, I'm just writing this section as a former Matlab user who likes my Python environment to look as Matlab-like as possible.  These recommendations will make the layout more Matlab-like, and will also reduce the visual complexity of the code editor.  These will also be good ways to practice editing VS Code configuration files.

* Choose a color theme you like...

  * You can browse themes at [vscodethemes.com](https://vscodethemes.com).
  * For a Matlab-y theme, I recommend the [Nord Light Brighter](https://vscodethemes.com/e/huytd.nord-light/nord-light-brighter) theme, but to each their own.
  * To install a new theme, click file &rarr; preferences &rarr; themes &rarr; color theme, or press "ctrl-k ctrl-t", then click "browse additional color schemes", and type the name of the theme you want.  Once you have installed a theme, you won't need to click "browse additional color schemes", it will just be there in the list of themes.
  * Click on the theme you want to download, click "OK", and click "Trust Publisher & Install" .

* Make the window layout more Matlab-like:

  * Press ctrl-, (that was control-comma) to open VS Code settings
  * Search for "workbench.panel.defaultlocation"
  * Change "bottom" to "right", like this:
  
    <img src="images/tools_workbench_location.jpg">

* Enable Matlab-like bookmarks (in Matlab, you can press ctrl-F2 to mark a line of code, then press F2 to move between marks)

  * Press ctrl-shift-x to bring up the extensions menu (or click the "extensions" icon in the side panel)
  
  * Search for and install the "Bookmarks" extension, which looks like this:
  
    <img src="images/tools_bookmarks_extension.jpg">
	
  * After installing that extension, the default keyboard shortcuts for this extension are:
  
    * Toggle a bookmark at the current location: ctrl-alt-K
	* Next bookmark: ctrl-alt-L
	* Previous bookmark: ctrl-alt-J
		
* Hide the "minimap", which is the super-fancy scrollbar on the right that smushes all your code into a column:
  
  <img src="images/tools_minimap.jpg">
	
  * Click on the minimap, and un-check "minimap"
  * If you want it back, click view &rarr; appearance &rarr; minimap
	
* If you are used to the clean look of code cells in Matlab, you may find this decoration at the top of every cell to be distracting (to each their own, but this former Matlab user can't stand it):
  
  <img src="images/tools_runcell.jpg">
  
  To disable that decoration:
  
  * Click ctrl-, (that was control-comma) to open settings
  * Search for "jupyter.codelens"
  * Un-check the "enable code lens" checkbox, which looks like this:
  
    <img src="images/tools_codelens.jpg">
 
  You can still run code cells using the keyboard.
    
* Hide this annoying yellow light bulb that appears all over your code:

  <img src="images/tools_lightbulb.jpg">

  * Open the settings.json file (press ctrl-shift-p, type “preferences: open user settings (json)”)
  
    You will see the settings.json
	
## Installing Miniforge

