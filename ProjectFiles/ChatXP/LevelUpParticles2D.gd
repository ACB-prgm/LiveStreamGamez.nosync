extends Particles2D_Plus



func _on_Particles2D_Plus_particles_cycle_finished():
	queue_free()
