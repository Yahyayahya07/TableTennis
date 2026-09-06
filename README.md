3D Table Tennis

A table tennis game built with Godot and GDScript. Control a racket with the mouse and play against a bot, using racket position and rotation to influence the ball's path.

This is a work-in-progress learning project focused on 3D movement, physics, collision handling, and gameplay programming.

Features

Mouse-controlled racket movement and racket rotation.

A bot opponent that follows the ball and swings to return it.

Assisted shots that calculate an arc toward a landing point on the opposite side of the table.

Crosscourt aiming based on the racket's position at impact.

Side spin based on racket tilt, with sideways curvature and visual ball rotation.

Ball reset after contact with the floor.

Controls

Input

Action

Mouse movement

Move the racket horizontally and vertically

Hold left mouse button and move the mouse vertically

Move the racket forward or backward

Left / right arrow

Rotate the racket around its Z axis

Hold right mouse button

Tilt the racket around its local X axis to swing

Escape

Quit the game

Running the project

Download or clone this repository.

Open Godot 4 and import the project's project.godot file.

Open the project in the editor.

Press F5 to run the game.

How the shots work

When a racket hits the ball, the game selects a landing point on the opponent's side. It calculates an initial velocity that sends the ball through an arc toward that point.

The racket's horizontal position shifts the target across the table. Its roll controls side spin, and the launch calculation compensates for the resulting sideways curve to help shots reach the chosen target.

This combines physics-driven movement with assisted aiming to make rallies easier to sustain.

Work in progress

Scoring: award a point based on the last side of the table the ball touched before reaching the floor. If it last touched the player's side, the bot scores, and vice versa. A rally with no table bounce currently awards no point. Moreover if ball hits side of table multiple times a play is not ended.

Design: Design of game is very limited.

Gameplay tuning: refine aiming assistance, spin strength, and bot behaviour.

The scoring system uses a simplified rule rather than full table tennis rules. Scoring and topspin are still being tested and refined.


CREDITS.
Professional Table Tennis free low-poly 3d model - archmark25
Table tennis pad - ErgoNumb

useful tutorials
Godot 4 Main Menu - Robottobani
How to do collision Detection - Bleh
Create Your First 3D Game - GodotAcademy

Built with

Godot 4

GDScript
