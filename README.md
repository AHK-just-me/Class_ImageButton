# Class_ImageButton #

Image Buttons for AHK GUIs.

## Features ##
The class creates an image list and assigns it to the pushbutton control. Button image lists may contain one or six images. If they contain only one image, the image will be used to draw all button states (i.e. the button won't be animated). Otherwise the images will be used to draw the appropriate six [button states](http://msdn.microsoft.com/en-us/windows/bb775975):  

    PBS_NORMAL    = 1
    PBS_HOT       = 2
    PBS_PRESSED   = 3
    PBS_DISABLED  = 4
    PBS_DEFAULTED = 5
    PBS_STYLUSHOT = 6 ; used only on tablet computers
    
## How to use ##

1. Create a push button (e.g. `Gui, Add, Button, vMyButton hwndHwndButton, Caption`) using the `Hwnd` option to get its HWND.

2. Call `ImageButton.Create()` passing three parameters:  
       
        HWND     -  Button's HWND.  
        Margins  -  Distance between the image and the button's borders in pixels.
	                Valid values:  0, 1, 2, 3, 4
	                Default value: 0
	    Options* -  variadic array containing up to 6 option arrays (see below).
    
	The index of each option array determines the corresponding button state for which the image will be shown (see above).  
  
    If you don't want the button to be 'animated' on themed GUIs, just pass one option array with index 1.  

    Each option array may contain the following values:  
    
        1. Background  -  mandatory for index 1, higher indices will use the value of index 1, if omitted.  
                          Unichrome:
                          -  RGB integer value (0xRRGGBB) or HTML color name ("Red").
                          Image:
                          -  Path of an image file or HBITMAP handle
                          3D-styled:
                          -  Array containing three values:
                             1. Outer color as RGB integer value (0xRRGGBB) or HTML color name ("Red").
                             2. Inner color as RGB integer value (0xRRGGBB) or HTML color name ("Red").
                             3. Mode: 1 = raised, 2 = horizontal gradient, 3 = vertical gradient
        2. TextColor   -  optional, if omitted, the default color will be used for index 1,  
                          higher indices will use the color of index 1.
                          -  RGB integer value (0xRRGGBB) or HTML color name ("Red").
                             Default: 0x000000 (black)  

	If the button has a caption it will be drawn above the image.  

3. That's all!

