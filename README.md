# VRC Collision Shader
Collision shader for VRChat.

You can find a video of this shader in action here: https://www.bitchute.com/video/55TwmaBkRY07/

This shader requires the use of the view camera's depth texture. For more information on how to set this up, Xiexe has good settings listed here:
https://github.com/Xiexe/XSVolumetrics/blob/master/README.md

For avatars, you'll either want to stick a directional light onto it with those settings or I guess only go to worlds that have those set up already.

# How to use
1. Make a blendshape on the model you want to add collision to in order to show what the mesh should look like when it is fully collided. 

2. Encode the blendshape into a texture by running the RedMage/Collision Shader/Encode Blendshape script. 

3. Apply the material it generates to your mesh.
