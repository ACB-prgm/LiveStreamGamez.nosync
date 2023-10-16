class_name XMLReader
# A high level class to allow for reading and parsing xml files.


var xml_dict := {}
var node_paths := []


# PARSERS ——————————————————————————————————————————————————————————————————————
func open_file(file_path:String) -> int:
	# Opens and parses an xml document that is stored in a file at `file_path`.
	# Returns a GlobalScope ERROR value
	xml_dict.clear()
	var parser = XMLParser.new()
	var ERR = parser.open(file_path)
	if ERR != OK:
		push_warning("XMLParser ERR %s" % ERR)
		return ERR
	
	ERR = parse(parser)
	if ERR != OK:
		return ERR
	
	return OK

func open_buffer(buffer:PoolByteArray) -> int:
	# Opens and parses an xml document that has been loaded into memory as a 
	# PoolByteArray. Returns a GlobalScope ERROR value
	var parser = XMLParser.new()
	var ERR = parser.open_buffer(buffer)
	if ERR != OK:
		push_warning("XMLParser ERR %s, unable to read buffer" % ERR)
		return ERR
	
	ERR = parse(parser)
	if ERR != OK:
		return ERR
	
	return OK

func open_string(string:String) -> int:
	# Opens and parses an xml document that has been loaded into memory as a
	# String. Returns a GlobalScope ERROR value
	return self.open_buffer(string.to_utf8())

func parse(parser:XMLParser) -> int:
	# Parses a xml document that has been opened with XMLParser and loads it
	# into a dictionary. This should only be used internally by open_file(), 
	# open_buffer(), and open_string(), but can be used if an instance of 
	# XMLParser is returned from some exogenous function.  Returns an Error.
	xml_dict.clear()
	node_paths.clear()
	
	var path := PoolStringArray()
	var nodes := []
	while parser.read() != ERR_FILE_EOF:
		match parser.get_node_type():
			parser.NODE_ELEMENT:
				var parent_node = get_element(path)
				var current_node = parser.get_node_name()
				
				nodes.append(current_node)
				current_node += "_%s" % (nodes.count(current_node) - 1)
				
				parent_node[current_node] = {}
				path.append(current_node)
				node_paths.append([current_node, path])
				
				var num_attrs = parser.get_attribute_count()
				if num_attrs:
					var attrs = "%s_attrs" % current_node
					parent_node[current_node][attrs] = {}
					attrs = parent_node[current_node][attrs]
					for idx in range(num_attrs):
						attrs[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
			parser.NODE_TEXT:
				if path:
					var parent_node = get_element(path)
					parent_node["%s_text" % path[-1]] = parser.get_node_data()
			parser.NODE_ELEMENT_END:
# warning-ignore:narrowing_conversion
				path.resize(max(0, path.size() - 1))
	
	if xml_dict.empty():
		return ERR_DOES_NOT_EXIST
	
	return OK


# ELEMENT AND PATH GETTERS ————————————————————————————————————————————————————————
func get_element(path:Array, dict:Dictionary=xml_dict) -> Dictionary:
	# Returns the dictionary of child nodes of a node at path.
	var element = dict
	for key in path:
		element = element.get(key)
	return element

func find_element(node_name:String) -> PoolStringArray:
	# Returns the path to node_name. If the node does not exist, returns an 
	# empty PoolStringArray.
	for node in node_paths:
		if node[0] == node_name:
			return node[1]
	return PoolStringArray()

func find_all_element(node_name:String) -> Array:
	# Returns an array of paths (PoolStringArrays) to all of node_name.
	# for this function, node_name is used without the _integer naming 
	# convention. eg, "Contents" will find Contents_0, ...Contents_0+n for as 
	# many exist If node_name does not exist, returns and empty Array.
	var paths := []
	for node in node_paths:
		if node[0] == node_name + ("_%s" % node[0].split("_")[-1]):
			paths.append(node[1])
	return paths

func find_and_get_element(node_name:String) -> Dictionary:
	# A simple helper function for the common use case of finding and getting an
	# element by name.
	return get_element(find_element(node_name))

func list_nodes() -> Array:
	# Returns an array of the node names in the xml document.
	var nodes := []
	for node in node_paths:
		nodes.append(node[0])
	return nodes

# QOL FUNCTIONS ————————————————————————————————————————————————————————————————
func prettify(delimeter:String="\t", dict:Dictionary=xml_dict) -> String:
	# Returns a "prettified" (readable) string of the xml dictionary.
	return JSON.print(dict, delimeter)


