# GodotSkate
Skate game prototype in Godot
![GodotS Skate Preview](/img/preview.png)
Textures by https://www.kenney.nl/

# Function Documentation
I tried to keep most function self explainatory

## characterBody3D

### _getStickCurve(path: Path3D,pos: Vector3)
Used to check if the player is on a curve.
Input is a path and the current global position of the player.
Returns true when the player is in a certain range of the baked curve. This range is in world units. The treshold value is .1. 
True range from .1 to curve length -.1. Otherwise it returns false.

### _getPathDir(tangnet: Vector3)
Returns the direction along the path based on a certain treshold. Used to check if the player will grind a rail or do lip movement.
Returns -1, 0 or 1. 0 will trigger lip movement.

### _getPathTangent(path: Path3D, pos: Vector3):
Returns the current tangent of the path based on the global player position.
Takes the last physics iteration and the current physics iteration to construct a tangent.
This is done by sampling to points on the curve based on current and last frame.

### _getClosestCurvePoint(path: Path3D, pos: Vector3)
Returns the closest point on a curve based on the global position of the player.

### _surfaceCheck()
Sets the isOnFloor and isOnWall boolean variables.
Im using a combination of is_on_floor() from the kinematicbody3d and a raycast to check if the player is on the floor. Using is_on_floor() only was not reliable enough. It caused jittering on slopes.

### _killOrthogonalVelocity(xForm : Transform3D, vel: Vector3)
Removes the orthogonal component from the player velocity. 

### _killPipeOrthogonalVelocity(vel: Vector3, tangent: Vector3)
Modifies the velocity so it follows the curve tangent.
Keeps the current y velocity but replaces the horizontal velocity based on the tangent.

## setupPark

Park setup runs only in the editor. It requires 3d models as packed gltf scenes.

Select a packed gltf-scene in the editor and run the script.

### setupPark requirements
![Park Setup](/img/parksetup.png)

- *assetname*_Col_Pipe -> **Pipe collision**
- *assetname*_Col_Floor -> **Floor collision**
- *assetname*_Col_Wall -> **Wall collision**

There can only be one of those 3 collision meshes inside of a packed scene. Concave colliders are created for each mesh. Keep them simple.

- *assetname*_Rail_*X* -> **Rail line**

Used to create rails, there can be multiple rails inside of one packed scene. Each rail needs a unique identifier. For example A,B,C etc. Rails need to be created as polylines. You need to take care of the vertex order. 
To order the vertices you can convert the polyline to a curve and then back to a mesh in blender. This will order vertices based on connectivity.
![Order Vertices](/img/vertexorder.png)
