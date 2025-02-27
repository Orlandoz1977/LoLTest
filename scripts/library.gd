class_name Library
# Base class for libraries

# Prevents instantiation of the library.
func _init():
	var name = self.get_class()
	assert(
		false,
		"{0} is not supposed to be initialized. Use its static functions directly.".format([name])
	)
