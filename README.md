# GodotSkate
Skate game prototype in Godot
![GodotS Skate Preview](/img/preview.png)
![GodotS Skate Preview](/img/character_preview.png)
Textures by https://www.kenney.nl/
Characters are based on low res metahuman characters by EPIC Games.

# Function Documentation
I tried to keep most function self explainatory

## character_controller

### _player_state()
Keeps track of the current player movement state and changes the state based on conditions.

### _surface_check()
Executes raycasts for the ground and the current movement direction.

### _get_path_tangent()
Returns the tangent of a path at a specific point.

### _get_path_dir()
Returns the direction along the path.

### _get_closest_curve_point()
Returns the position on a curve based on the current location.

### _get_closest_curve_offset()
Returns the offset value of the curve. A value between 0 and the curve length.

### _get_stick_curve()
Returns true of the player should be attached to a curve, false if the player leaves the curve.

### _set_up_direction()
Calculates the upvector.

### _lerp_vis_transform()
Interpolates the visible player transform to avoid jittery motion because of lowres colliders.

### _fall()
Falling logic.

### _reset_player()
Resets the player to the starting location, resets all player values.

### _input_handler()
Read and map inputs.

### _animation_handler()
Controls the animtree.

### _kill_orthogonal_velocity()
Removes orthogonal velocity of the player.

### _kill_pipe_orthogonal_velocity()
Removes orthogonal velocity on a pipe.

### _align()
Aligns the player with the groud.

### _limit_velocity()
Speed limit.

### _revert_motion()
Turns the player to follow the movement direction.

### _ground_movement()
Ground movement logic.

### _air_movement()
Air movement logic.

### _pipe_snap_movement()
Movement logic while snapped to a pipe.

### _grind_movement()
Grinding movement logic.

### _lip_movement()
Lip movement logic.

### _randomize_balance()
Randomize balance direction.

### _init_player()
Initialize the player.

### _check_reverse_motion()
Checkup to execute the revert motion function.

### _check_bounce_grind()
Checkup if the player bounces off a wall while grinding.

### _check_bounce()
Checkup if the player bounces off a wall.

###_debug_player_state()
Prints debug infos.

### _jump_timer()
Timer function to get the time since the last jump.

### _forward_velocity()
Returns forward component of velocity.

### _raycast()
Raycast function.

### _fall_check()
Checks if the player should fall.

## setup_park

Park setup runs only in the editor. It requires 3d models as packed gltf scenes.

Select a packed gltf-scene in the editor and run the script.

### setup_park requirements
![Park Setup](/img/parksetup.png)

- *assetname*_Col_Pipe -> **Pipe collision**
- *assetname*_Col_Floor -> **Floor collision**
- *assetname*_Col_Wall -> **Wall collision**

There can only be one of those 3 collision meshes inside of a packed scene. Concave colliders are created for each mesh. Keep them simple.

- *assetname*_Rail_*X* -> **Rail line**

Used to create rails, there can be multiple rails inside of one packed scene. Each rail needs a unique identifier. For example A,B,C etc. Rails need to be created as polylines. You need to take care of the vertex order. 
To order the vertices you can convert the polyline to a curve and then back to a mesh in blender. This will order vertices based on connectivity.
![Order Vertices](/img/vertexorder.png)
