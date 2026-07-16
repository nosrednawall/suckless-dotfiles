#include <strings.h>

int cfg_window_width = 800;
int cfg_window_height = 600;
int cfg_window_top_statusbar = 0;
float *cfg_zoom_levels = NULL;
int cfg_image_slideshow_delay = 5;
int cfg_image_pan_fraction = 5;
int cfg_image_cc_steps = 32;
double cfg_image_gamma_max = 10.0;
double cfg_image_brightness_max = 2.0;
double cfg_image_contrast_max = 4.0;
int cfg_image_cache_size_mem_percentage = 3;
int cfg_image_cache_size_limit = 268435456;
int cfg_image_cache_size_fallback = 33554432;
int cfg_options_anti_alias = 1;
int cfg_options_alpha_layer = 0;
int cfg_options_tns_blacklist = 0;
char *cfg_options_tns_filters = 0;
int *cfg_thumb_sizes = NULL;
int cfg_thumb_sizes_idx = 0;
uint64_t settings = 0;
keymap_t *cfg_keys = NULL;
button_t *cfg_buttons_img = NULL;
button_t *cfg_buttons_tns = NULL;
KeySym cfg_keyhandler_abort = XK_Escape;
int cfg_navigation_width = 33;
int cfg_navigation_width_is_rel = 1;
static Command *cfg_commands = NULL;
char nsxiv_window_id[64]; /* will be set to nsxiv's window ID */

static const cursor_t cfg_image_cursor[3] = {
	CURSOR_LEFT, CURSOR_ARROW, CURSOR_RIGHT
};

int num_zoom_levels = 0;
int num_thumb_sizes = 0;
int num_key_bindings = 0;
int num_commands = 0;
int num_button_img_bindings = 0;
int num_button_tns_bindings = 0;

typedef struct {
    const char *name;
    cmd_f func;
    appmode_t mode;
} funcmap_t;

void
cleanup_config(void)
{
	int i, j;
	free(cfg_zoom_levels);
	free(cfg_options_tns_filters);

	/* Cleanup commands */
	if (cfg_commands != NULL) {
		for (i = 0; i < num_commands; i++) {
			free(cfg_commands[i].name);
			for (j = 0; cfg_commands[i].argv[j] != NULL; j++) {
				if (cfg_commands[i].argv[j] == nsxiv_window_id)
					continue;
				free(cfg_commands[i].argv[j]);
			}
		}
		free(cfg_commands);
	}
}

void
load_config(void)
{
	config_t cfg;

	char *filename = xasprintf("%s.cfg", progname);
	char *config_file = get_config_path(filename);

	if (!config_file)
		return;

	config_init(&cfg);
	char *config_path = path_dirname(config_file);
	config_set_include_dir(&cfg, config_path);

	if (!config_read_file(&cfg, config_file)) {
		if (!strcmp(config_error_text(&cfg), "file I/O error")) {
			fprintf(stderr, "No configuration file found, expected to find %s\n", config_file);
		} else {
			fprintf(stderr, "Error reading config at %s\n", config_file);
			fprintf(stderr, "%s:%d - %s\n",
				config_error_file(&cfg),
				config_error_line(&cfg),
				config_error_text(&cfg)
			);
		}

		config_destroy(&cfg);
		exit(1);
	}

	load_functionality_settings(&cfg);
	load_window_settings(&cfg);
	load_image_settings(&cfg);
	load_keybindings_settings(&cfg);
	load_button_bindings_settings(&cfg);
	load_options_settings(&cfg);
	load_thumbnail_settings(&cfg);
	load_main_settings(&cfg);
	load_command_settings(&cfg);

	config_destroy(&cfg);

	free(filename);
	free(config_file);
	free(config_path);
}

void
load_fallback_config(void)
{
	config_t cfg;
	config_setting_t *root, *group_t, *setting_t;

	config_init(&cfg);
	root = config_root_setting(&cfg);

	if (!cfg_zoom_levels) {
		group_t = config_setting_add(root, "image", CONFIG_TYPE_GROUP);

		setting_t = config_setting_add(group_t, "zoom_levels", CONFIG_TYPE_ARRAY);
		config_setting_set_float_elem(setting_t, -1, 12.5);
		config_setting_set_float_elem(setting_t, -1, 25.0);
		config_setting_set_float_elem(setting_t, -1, 50.0);
		config_setting_set_float_elem(setting_t, -1, 75.0);
		config_setting_set_float_elem(setting_t, -1, 100.0);
		config_setting_set_float_elem(setting_t, -1, 150.0);
		config_setting_set_float_elem(setting_t, -1, 200.0);
		config_setting_set_float_elem(setting_t, -1, 400.0);
		config_setting_set_float_elem(setting_t, -1, 800.0);

		load_zoom_levels(setting_t);
	}

	if (!cfg_thumb_sizes) {
		group_t = config_setting_add(root, "thumbnail", CONFIG_TYPE_GROUP);

		setting_t = config_setting_add(group_t, "sizes", CONFIG_TYPE_ARRAY);
		config_setting_set_int_elem(setting_t, -1, 32);
		config_setting_set_int_elem(setting_t, -1, 64);
		config_setting_set_int_elem(setting_t, -1, 96);
		config_setting_set_int_elem(setting_t, -1, 128);
		config_setting_set_int_elem(setting_t, -1, 160);

		setting_t = config_setting_add(group_t, "initial_thumbnail_size", CONFIG_TYPE_INT);
		config_setting_set_int(setting_t, 96);

		load_thumbnail_settings(&cfg);
	}

	if (!cfg_options_tns_filters) {
		cfg_options_tns_filters = strdup("");
	}

	config_destroy(&cfg);
}

void
load_image_settings(const config_t *cfg)
{
	int mib;

	config_lookup_int(cfg, "image.slideshow_delay", &cfg_image_slideshow_delay);
	config_lookup_int(cfg, "image.pan_fraction", &cfg_image_pan_fraction);

	config_lookup_int(cfg, "image.color_correction_steps", &cfg_image_cc_steps);
	config_lookup_float(cfg, "image.gamma_max", &cfg_image_gamma_max);
	config_lookup_float(cfg, "image.brightness_max", &cfg_image_brightness_max);
	config_lookup_float(cfg, "image.contrast_max", &cfg_image_contrast_max);

	config_lookup_int(cfg, "image.cache_size.mem_percentage", &cfg_image_cache_size_mem_percentage);
	if (config_lookup_int(cfg, "image.cache_size.limit", &mib))
		cfg_image_cache_size_limit = mib * 1024 * 1024;
	if (config_lookup_int(cfg, "image.cache_size.fallback", &mib))
		cfg_image_cache_size_fallback = mib * 1024 * 1024;

	load_zoom_levels(config_lookup(cfg, "image.zoom_levels"));
}

void
load_keybindings_settings(const config_t *cfg)
{
	const char *string;
	int i, j, k, num_bindings, num_expanded_bindings, length;
	int num_modifiers, num_keys, num_functions, num_arguments;
	unsigned int modifier_arr[20] = {0};
	KeySym key_arr[20] = {0};
	cmd_f function_arr[20] = {0};
	appmode_t mode_arr[20] = {0};
	int argument_arr[20] = {0};

	const config_setting_t *bindings_t, *binding_t, *modifier, *key, *function, *argument, *arg;

	bindings_t = config_lookup(cfg, "keybindings");
	if (!bindings_t || !config_setting_is_list(bindings_t))
		return;

	num_bindings = config_setting_length(bindings_t);
	if (!num_bindings)
		return;

	cfg_keys = ecalloc(MAX(num_bindings * 2, 200), sizeof(keymap_t));
	Display *dpy = XOpenDisplay(NULL);

	/* Parse and set the key bindings based on config */
	for (i = 0; i < num_bindings; i++) {
		binding_t = config_setting_get_elem(bindings_t, i);
		modifier = config_setting_lookup(binding_t, "modifier");
		key = config_setting_lookup(binding_t, "key");
		function = config_setting_lookup(binding_t, "function");
		argument = config_setting_lookup(binding_t, "argument");

		modifier_arr[0] = 0;
		function_arr[0] = NULL;
		mode_arr[0] = 0;
		argument_arr[0] = 0;
		key_arr[0] = 0;

		length = setting_length(modifier);
		num_modifiers = MAX(length, 1);
		for (j = 0; j < length; j++) {
			modifier_arr[j] = parse_modifier(setting_get_string_elem(modifier, j));
		}

		length = setting_length(function);
		num_functions = MAX(length, 1);
		for (j = 0; j < length; j++) {
			function_arr[j] = parse_function(setting_get_string_elem(function, j), &mode_arr[j]);
		}

		length = setting_length(argument);
		num_arguments = MAX(length, 1);
		for (j = 0; j < length; j++) {
			arg = setting_get_elem(argument, j);
			switch (config_setting_type(arg)) {
			case CONFIG_TYPE_INT:
				argument_arr[j] = config_setting_get_int(arg);
				break;
			case CONFIG_TYPE_STRING:
				argument_arr[j] = parse_function_int_constant(config_setting_get_string(arg));
				break;
			}
		}

		length = setting_length(key);
		num_keys = MAX(length, 1);

		/* Since we may be adding ShiftMask for keybindings that are defined with second
		 * level keysyms, e.g. "A" instead of "a", we duplicate the modifiers here to
		 * match that of the number of keys. */
		for (int m = num_modifiers; m < num_keys; m++) {
			modifier_arr[m] = modifier_arr[m % num_modifiers];
		}
		num_modifiers = num_keys;

		for (j = 0; j < length; j++) {
			string = setting_get_string_elem(key, j);
			KeySym keysym = parse_keysym(string);
			KeyCode kc = XKeysymToKeycode(dpy, keysym);
			if (kc) {
				KeySym base = XKeycodeToKeysym(dpy, kc, 0);
				KeySym shifted = XKeycodeToKeysym(dpy, kc, 1);

				if (keysym == shifted && shifted != base) {
					keysym = base;
					modifier_arr[j] |= ShiftMask;
				}
			}

			key_arr[j] = keysym;

			if (key_arr[j] == NoSymbol) {
				fprintf(stderr, "Warning: config could not look up keysym for key %s\n", string);
			}
		}

		/* Figure out the maximum number of expanded keybindings */
		int counts[4] = {num_modifiers, num_functions, num_arguments, num_keys};
		num_expanded_bindings = counts[0];
		for (k = 1; k < 4; k++)
			if (counts[k] > num_expanded_bindings)
				num_expanded_bindings = counts[k];

		/* Finally add each keybinding */
		for (j = 0; j < num_expanded_bindings; j++) {
			add_key_binding(
				modifier_arr[j % num_modifiers],
				key_arr[j % num_keys],
				function_arr[j % num_functions],
				mode_arr[j % num_functions],
				argument_arr[j % num_arguments]
			);
		}
	}

	/* Trim the allocated memory down to the number of key bindings actually used */
	cfg_keys = realloc(cfg_keys, num_key_bindings * sizeof(keymap_t));

	XCloseDisplay(dpy);
}

void
add_key_binding(
	unsigned int mask,
	KeySym keysym,
	cmd_f function,
	appmode_t mode,
	int argument
) {
	cfg_keys[num_key_bindings].mask = mask;
	cfg_keys[num_key_bindings].keysym = keysym;
	cfg_keys[num_key_bindings].func = function;
	cfg_keys[num_key_bindings].mode = mode;
	cfg_keys[num_key_bindings].arg = argument;

	num_key_bindings++;
}

void
load_button_bindings_settings(const config_t *cfg)
{
	const config_setting_t *bindings_t;

	bindings_t = config_lookup(cfg, "image_button_bindings");
	load_button_settings_for(bindings_t, &cfg_buttons_img, &num_button_img_bindings);

	bindings_t = config_lookup(cfg, "thumbnail_button_bindings");
	load_button_settings_for(bindings_t, &cfg_buttons_tns, &num_button_tns_bindings);
}

void
load_button_settings_for(const config_setting_t *bindings_t, button_t **buttons, int *num_button_bindings)
{
	int i, j, k, num_bindings, num_expanded_bindings, length;
	int num_modifiers, num_buttons, num_functions, num_arguments;
	unsigned int modifier_arr[20] = {0};
	KeySym button_arr[20] = {0};
	cmd_f function_arr[20] = {0};
	appmode_t mode_arr[20] = {0};
	int argument_arr[20] = {0};

	const config_setting_t *binding_t, *modifier, *button, *function, *argument, *arg;

	if (!bindings_t || !config_setting_is_list(bindings_t))
		return;

	num_bindings = config_setting_length(bindings_t);
	if (!num_bindings)
		return;

	*buttons = ecalloc(MAX(num_bindings * 2, 200), sizeof(button_t));

	/* Parse and set the key bindings based on config */
	for (i = 0; i < num_bindings; i++) {
		binding_t = config_setting_get_elem(bindings_t, i);
		modifier = config_setting_lookup(binding_t, "modifier");
		button = config_setting_lookup(binding_t, "button");
		function = config_setting_lookup(binding_t, "function");
		argument = config_setting_lookup(binding_t, "argument");

		modifier_arr[0] = 0;
		function_arr[0] = NULL;
		mode_arr[0] = 0;
		argument_arr[0] = 0;
		button_arr[0] = 0;

		length = setting_length(modifier);
		num_modifiers = MAX(length, 1);
		for (j = 0; j < length; j++) {
			modifier_arr[j] = parse_modifier(setting_get_string_elem(modifier, j));
		}

		length = setting_length(function);
		num_functions = MAX(length, 1);
		for (j = 0; j < length; j++) {
			function_arr[j] = parse_function(setting_get_string_elem(function, j), &mode_arr[j]);
		}

		length = setting_length(argument);
		num_arguments = MAX(length, 1);
		for (j = 0; j < length; j++) {
			arg = setting_get_elem(argument, j);
			switch (config_setting_type(arg)) {
			case CONFIG_TYPE_INT:
				argument_arr[j] = config_setting_get_int(arg);
				break;
			case CONFIG_TYPE_STRING:
				argument_arr[j] = parse_function_int_constant(config_setting_get_string(arg));
				break;
			}
		}

		length = setting_length(button);
		num_buttons = MAX(length, 1);
		for (j = 0; j < length; j++) {
			button_arr[j] = setting_get_int_elem(button, j);;
		}

		/* Figure out the maximum number of expanded button bindings */
		int counts[4] = {num_modifiers, num_functions, num_arguments, num_buttons};
		num_expanded_bindings = counts[0];
		for (k = 1; k < 4; k++)
			if (counts[k] > num_expanded_bindings)
				num_expanded_bindings = counts[k];

		/* Finally add each button binding */
		for (j = 0; j < num_expanded_bindings; j++) {

			add_button_binding(
				buttons,
				num_button_bindings,
				modifier_arr[j % num_modifiers],
				button_arr[j % num_buttons],
				function_arr[j % num_functions],
				mode_arr[j % num_functions],
				argument_arr[j % num_arguments]
			);
		}
	}

	*buttons = realloc(*buttons, *num_button_bindings * sizeof(button_t));
}

void
add_button_binding(
	button_t **buttons,
	int *num_button_bindings,
	unsigned int mask,
	KeySym keysym,
	cmd_f function,
	appmode_t mode,
	int argument
) {
	(*buttons)[*num_button_bindings].mask = mask;
	(*buttons)[*num_button_bindings].keysym = keysym;
	(*buttons)[*num_button_bindings].func = function;
	(*buttons)[*num_button_bindings].mode = mode;
	(*buttons)[*num_button_bindings].arg = argument;

	(*num_button_bindings)++;
}

void
load_thumbnail_settings(const config_t *cfg)
{
	int i, initial_size;
	const config_setting_t *sizes_t;

	sizes_t = config_lookup(cfg, "thumbnail.sizes");
	if (!sizes_t)
		return;

	num_thumb_sizes = setting_length(sizes_t);
	if (!num_thumb_sizes)
		return;

	cfg_thumb_sizes = ecalloc(num_thumb_sizes, sizeof(int));

	for (i = 0; i < num_thumb_sizes; i++) {
		cfg_thumb_sizes[i] = setting_get_int_elem(sizes_t, i);
	}

	if (config_lookup_int(cfg, "thumbnail.initial_thumbnail_size", &initial_size)) {
		for (i = 0; i < num_thumb_sizes; i++) {
			if (cfg_thumb_sizes[i] <= initial_size) {
				cfg_thumb_sizes_idx = i;
			}
		}
	}
}

void
load_zoom_levels(const config_setting_t *zoom_levels_t)
{
	int i;
	const config_setting_t *zl_t;

	num_zoom_levels = setting_length(zoom_levels_t);
	if (!num_zoom_levels)
		return;

	cfg_zoom_levels = ecalloc(num_zoom_levels, sizeof(float));

	for (i = 0; i < num_zoom_levels; i++) {
		zl_t = setting_get_elem(zoom_levels_t, i);
		cfg_zoom_levels[i] = (float)setting_get_float_elem(zl_t, i) / 100;
	}
}

void
load_window_settings(const config_t *cfg)
{
	config_lookup_int(cfg, "window.width", &cfg_window_width);
	config_lookup_int(cfg, "window.height", &cfg_window_height);
	config_lookup_sloppy_bool(cfg, "window.top_statusbar", &cfg_window_top_statusbar);
}

void
load_main_settings(const config_t *cfg)
{
	const char *string;
	const config_setting_t *nav_width_t;

	if (config_lookup_string(cfg, "main.keyhandler_abort_key", &string))
		cfg_keyhandler_abort = parse_keysym(string);

	nav_width_t = config_lookup(cfg, "main.navigation_area_width");
	if (nav_width_t) {
		switch (config_setting_type(nav_width_t)) {
		case CONFIG_TYPE_INT:
			cfg_navigation_width = config_setting_get_int(nav_width_t);
			cfg_navigation_width_is_rel = 0;
			break;
		case CONFIG_TYPE_STRING:
			string = config_setting_get_string(nav_width_t);
			size_t len = strlen(string);
			cfg_navigation_width = atoi(string);
			cfg_navigation_width_is_rel = (len > 0 && string[len - 1] == '%');
			break;
		}
	}
}

void
load_command_settings(const config_t *cfg)
{
	int i, j, num_cmd_elements;
	const char *string;
	config_setting_t *commands_list, *command_entry, *command_t;
	Command *command;

	commands_list = config_lookup(cfg, "commands");
	if (!commands_list || !config_setting_is_list(commands_list))
		return;

	num_commands = config_setting_length(commands_list);
	if (!num_commands)
		return;

	cfg_commands = ecalloc(num_commands, sizeof(Command));
	for (i = 0; i < num_commands; i++) {
		command = &cfg_commands[i];
		command->name = NULL;
		command->argv = NULL;

		command_entry = config_setting_get_elem(commands_list, i);
		config_setting_lookup_strdup(command_entry, "name", &command->name);

		command_t = config_setting_lookup(command_entry, "command");
		num_cmd_elements = config_setting_length(command_t);
		command->argv = ecalloc(num_cmd_elements + 1, sizeof(char*));

		for (j = 0; j < num_cmd_elements; j++) {
			string = config_setting_get_string_elem(command_t, j);
			if (!strcasecmp(string, "%WINDOW%")) {
				command->argv[j] = nsxiv_window_id;
			} else {
				command->argv[j] = strdup(string);
			}
		}
		command->argv[j + 1] = NULL;

		if (command->name == NULL || command->argv == NULL) {
			fprintf(stderr, "Warning: config found incomplete command at line %d\n", config_setting_source_line(command_entry));
		}
	}
}

void
load_options_settings(const config_t *cfg)
{
	const char *string;

	config_lookup_sloppy_bool(cfg, "options.anti_alias", &cfg_options_anti_alias);
	config_lookup_sloppy_bool(cfg, "options.alpha_layer", &cfg_options_alpha_layer);

	if (config_lookup_string(cfg, "options.thumbnail_blacklisted_directories", &string)) {
		cfg_options_tns_filters = strdup(string);
		cfg_options_tns_blacklist = 1;
	} else if (config_lookup_string(cfg, "options.thumbnail_whitelisted_directories", &string)) {
		cfg_options_tns_filters = strdup(string);
		cfg_options_tns_blacklist = 0;
	}
}

void
load_functionality_settings(const config_t *cfg)
{
	int i, enabled;

	const config_setting_t *func_t = config_lookup(cfg, "functionality");
	if (!func_t)
		return;

	for (i = 0; functionality_names[i].name != NULL; i++) {
		if (config_setting_lookup_sloppy_bool(func_t, functionality_names[i].name, &enabled)) {
			setenabled(functionality_names[i].value, enabled);
		}
	}
}

KeySym
parse_keysym(const char *string)
{
	typedef struct {
		const char *glyph;
		KeySym keysym;
	} glyphmap_t;

	static const glyphmap_t glyphmap[] = {
		{ "Escape", XK_Escape },
		{ "Esc", XK_Escape },
		{ "Enter", XK_Return },
		{ " ", XK_space },
		{ "!", XK_exclam },
		{ "\"", XK_quotedbl },
		{ "#", XK_numbersign },
		{ "$", XK_dollar },
		{ "%", XK_percent },
		{ "&", XK_ampersand },
		{ "'", XK_apostrophe },
		{ "(", XK_parenleft },
		{ ")", XK_parenright },
		{ "*", XK_asterisk },
		{ "+", XK_plus },
		{ ",", XK_comma },
		{ "-", XK_minus },
		{ ".", XK_period },
		{ "/", XK_slash },
		{ "0", XK_0 },
		{ "1", XK_1 },
		{ "2", XK_2 },
		{ "3", XK_3 },
		{ "4", XK_4 },
		{ "5", XK_5 },
		{ "6", XK_6 },
		{ "7", XK_7 },
		{ "8", XK_8 },
		{ "9", XK_9 },
		{ ":", XK_colon },
		{ ";", XK_semicolon },
		{ "<", XK_less },
		{ "=", XK_equal },
		{ ">", XK_greater },
		{ "?", XK_question },
		{ "@", XK_at },
		{ "A", XK_A },
		{ "B", XK_B },
		{ "C", XK_C },
		{ "D", XK_D },
		{ "E", XK_E },
		{ "F", XK_F },
		{ "G", XK_G },
		{ "H", XK_H },
		{ "I", XK_I },
		{ "J", XK_J },
		{ "K", XK_K },
		{ "L", XK_L },
		{ "M", XK_M },
		{ "N", XK_N },
		{ "O", XK_O },
		{ "P", XK_P },
		{ "Q", XK_Q },
		{ "R", XK_R },
		{ "S", XK_S },
		{ "T", XK_T },
		{ "U", XK_U },
		{ "V", XK_V },
		{ "W", XK_W },
		{ "X", XK_X },
		{ "Y", XK_Y },
		{ "Z", XK_Z },
		{ "[", XK_bracketleft },
		{ "\\", XK_backslash },
		{ "]", XK_bracketright },
		{ "^", XK_asciicircum },
		{ "_", XK_underscore },
		{ "`", XK_grave },
		{ "a", XK_a },
		{ "b", XK_b },
		{ "c", XK_c },
		{ "d", XK_d },
		{ "e", XK_e },
		{ "f", XK_f },
		{ "g", XK_g },
		{ "h", XK_h },
		{ "i", XK_i },
		{ "j", XK_j },
		{ "k", XK_k },
		{ "l", XK_l },
		{ "m", XK_m },
		{ "n", XK_n },
		{ "o", XK_o },
		{ "p", XK_p },
		{ "q", XK_q },
		{ "r", XK_r },
		{ "s", XK_s },
		{ "t", XK_t },
		{ "u", XK_u },
		{ "v", XK_v },
		{ "w", XK_w },
		{ "x", XK_x },
		{ "y", XK_y },
		{ "z", XK_z },
		{ "{", XK_braceleft },
		{ "|", XK_bar },
		{ "}", XK_braceright },
		{ "~", XK_asciitilde },
		{ " ", XK_nobreakspace },
		{ "¡", XK_exclamdown },
		{ "¢", XK_cent },
		{ "£", XK_sterling },
		{ "¤", XK_currency },
		{ "¥", XK_yen },
		{ "¦", XK_brokenbar },
		{ "§", XK_section },
		{ "¨", XK_diaeresis },
		{ "©", XK_copyright },
		{ "ª", XK_ordfeminine },
		{ "«", XK_guillemotleft },
		{ "«", XK_guillemetleft },
		{ "¬", XK_notsign },
		{ "®", XK_registered },
		{ "¯", XK_macron },
		{ "°", XK_degree },
		{ "±", XK_plusminus },
		{ "²", XK_twosuperior },
		{ "³", XK_threesuperior },
		{ "´", XK_acute },
		{ "µ", XK_mu },
		{ "¶", XK_paragraph },
		{ "·", XK_periodcentered },
		{ "¸", XK_cedilla },
		{ "¹", XK_onesuperior },
		{ "º", XK_masculine },
		{ "º", XK_ordmasculine },
		{ "»", XK_guillemotright },
		{ "»", XK_guillemetright },
		{ "¼", XK_onequarter },
		{ "½", XK_onehalf },
		{ "¾", XK_threequarters },
		{ "¿", XK_questiondown },
		{ "À", XK_Agrave },
		{ "Á", XK_Aacute },
		{ "Â", XK_Acircumflex },
		{ "Ã", XK_Atilde },
		{ "Ä", XK_Adiaeresis },
		{ "Å", XK_Aring },
		{ "Æ", XK_AE },
		{ "Ç", XK_Ccedilla },
		{ "È", XK_Egrave },
		{ "É", XK_Eacute },
		{ "Ê", XK_Ecircumflex },
		{ "Ë", XK_Ediaeresis },
		{ "Ì", XK_Igrave },
		{ "Í", XK_Iacute },
		{ "Î", XK_Icircumflex },
		{ "Ï", XK_Idiaeresis },
		{ "Ð", XK_ETH },
		{ "Ð", XK_Eth },
		{ "Ñ", XK_Ntilde },
		{ "Ò", XK_Ograve },
		{ "Ó", XK_Oacute },
		{ "Ô", XK_Ocircumflex },
		{ "Õ", XK_Otilde },
		{ "Ö", XK_Odiaeresis },
		{ "×", XK_multiply },
		{ "Ø", XK_Oslash },
		{ "Ø", XK_Ooblique },
		{ "Ù", XK_Ugrave },
		{ "Ú", XK_Uacute },
		{ "Û", XK_Ucircumflex },
		{ "Ü", XK_Udiaeresis },
		{ "Ý", XK_Yacute },
		{ "Þ", XK_THORN },
		{ "Þ", XK_Thorn },
		{ "ß", XK_ssharp },
		{ "à", XK_agrave },
		{ "á", XK_aacute },
		{ "â", XK_acircumflex },
		{ "ã", XK_atilde },
		{ "ä", XK_adiaeresis },
		{ "å", XK_aring },
		{ "æ", XK_ae },
		{ "ç", XK_ccedilla },
		{ "è", XK_egrave },
		{ "é", XK_eacute },
		{ "ê", XK_ecircumflex },
		{ "ë", XK_ediaeresis },
		{ "ì", XK_igrave },
		{ "í", XK_iacute },
		{ "î", XK_icircumflex },
		{ "ï", XK_idiaeresis },
		{ "ð", XK_eth },
		{ "ñ", XK_ntilde },
		{ "ò", XK_ograve },
		{ "ó", XK_oacute },
		{ "ô", XK_ocircumflex },
		{ "õ", XK_otilde },
		{ "ö", XK_odiaeresis },
		{ "÷", XK_division },
		{ "ø", XK_oslash },
		{ "ø", XK_ooblique },
		{ "ù", XK_ugrave },
		{ "ú", XK_uacute },
		{ "û", XK_ucircumflex },
		{ "ü", XK_udiaeresis },
		{ "ý", XK_yacute },
		{ "þ", XK_thorn },
		{ "ÿ", XK_ydiaeresis },
	};

	KeySym keysym = XStringToKeysym(string);
	if (keysym == NoSymbol) {
		for (size_t i = 0; i < ARRLEN(glyphmap); i++) {
			if (!strcasecmp(string, glyphmap[i].glyph)) {
				keysym = glyphmap[i].keysym;
				break;
			}
		}
	}

	return keysym;
}

unsigned int
parse_modifier(const char *string)
{
	int i, len;
	unsigned int mask = 0;
	len = strlen(string) + 1;
	char buffer[len];
	strncpy(buffer, string, len);
	const char *delims = "+-|:;, ";
	const char *modifier_strings[] = {
		"Super",
		"AltGr",
		"Alt",
		"ShiftGr",
		"Shift",
		"Ctrl",
		"Control",
		NULL
	};
	const unsigned int modifier_values[] = {
		Mod4Mask,
		Mod3Mask,
		Mod1Mask,
		Mod5Mask,
		ShiftMask,
		ControlMask,
		ControlMask
	};

	char *token = strtok(buffer, delims);
	while (token) {
		for (i = 0; modifier_strings[i]; i++) {
			if (!strcasecmp(token, modifier_strings[i])) {
				mask |= modifier_values[i];
				break;
			}
		}
		token = strtok(NULL, delims);
	}

	return mask;
}

cmd_f
parse_function(const char *string, appmode_t *mode)
{
	static const funcmap_t funcmap[] = {
		{ "change_gamma",       cg_change_gamma,       MODE_ALL },
		{ "change_brightness",  cg_change_brightness,  MODE_ALL },
		{ "change_contrast",    cg_change_contrast,    MODE_ALL },
		{ "dmenu_search",       cg_dmenu_search,       MODE_ALL },
		{ "first",              cg_first,              MODE_ALL },
		{ "mark_range",         cg_mark_range,         MODE_ALL },
		{ "n_or_last",          cg_n_or_last,          MODE_ALL },
		{ "navigate_marked",    cg_navigate_marked,    MODE_ALL },
		{ "nav_dir",            cg_nav_dir,            MODE_ALL },
		{ "prefix_external",    cg_prefix_external,    MODE_ALL },
		{ "quit",               cg_quit,               MODE_ALL },
		{ "pick_quit",          cg_pick_quit,          MODE_ALL },
		{ "random_image",       cg_random_image,       MODE_ALL },
		{ "reload_image",       cg_reload_image,       MODE_ALL },
		{ "remove_image",       cg_remove_image,       MODE_ALL },
		{ "reverse_marks",      cg_reverse_marks,      MODE_ALL },
		{ "scroll_screen",      cg_scroll_screen,      MODE_ALL },
		{ "switch_mode",        cg_switch_mode,        MODE_ALL },
		{ "toggle_bar",         cg_toggle_bar,         MODE_ALL },
		{ "toggle_invert",      cg_toggle_invert,      MODE_ALL },
		{ "toggle_fullscreen",  cg_toggle_fullscreen,  MODE_ALL },
		{ "toggle_image_mark",  cg_toggle_image_mark,  MODE_ALL },
		{ "unmark_all",         cg_unmark_all,         MODE_ALL },
		{ "zoom",               cg_zoom,               MODE_ALL },
		{ "alternate",          ci_alternate,          MODE_IMAGE },
		{ "cursor_navigate",    ci_cursor_navigate,    MODE_IMAGE },
		{ "drag",               ci_drag,               MODE_IMAGE },
		{ "fit_to_win",         ci_fit_to_win,         MODE_IMAGE },
		{ "flip",               ci_flip,               MODE_IMAGE },
		{ "navigate",           ci_navigate,           MODE_IMAGE },
		{ "navigate_frame",     ci_navigate_frame,     MODE_IMAGE },
		{ "rotate",             ci_rotate,             MODE_IMAGE },
		{ "scroll_image",       ci_scroll_image,       MODE_IMAGE },
		{ "scroll_to_center",   ci_scroll_to_center,   MODE_IMAGE },
		{ "scroll_to_edge",     ci_scroll_to_edge,     MODE_IMAGE },
		{ "set_zoom",           ci_set_zoom,           MODE_IMAGE },
		{ "slideshow",          ci_slideshow,          MODE_IMAGE },
		{ "toggle_alpha",       ci_toggle_alpha,       MODE_IMAGE },
		{ "toggle_animation",   ci_toggle_animation,   MODE_IMAGE },
		{ "toggle_antialias",   ci_toggle_antialias,   MODE_IMAGE },
		{ "move_sel",           ct_move_sel,           MODE_THUMB },
		{ "reload_all",         ct_reload_all,         MODE_THUMB },
		{ "scroll_thumbnails",  ct_scroll_thumbnails,  MODE_THUMB },
		{ "drag_mark_image",    ct_drag_mark_image,    MODE_THUMB },
		{ "select",             ct_select,             MODE_THUMB },
	};

	if (startswith("cg_", string) || startswith("ci_", string) || startswith("ct_", string))
		string += 3;
	else if (startswith("g_", string) || startswith("i_", string) || startswith("t_", string))
		string += 2;

    for (size_t i = 0; i < ARRLEN(funcmap); i++) {
        if (!strcasecmp(string, funcmap[i].name)) {
            *mode = funcmap[i].mode;
            return funcmap[i].func;
        }
    }

	return NULL;
}

#define map(S, I) if (!strcasecmp(string, S)) { return I; };

void *
cfg_get_command(const char *string)
{
	int i;

	for (i = 0; i < num_commands; i++) {
		if (!strcasecmp(string, cfg_commands[i].name)) {
			return cfg_commands[i].argv;
		}
	}

	return NULL;
}

/* This attempts to parse function specific constants.
 * If a constant is found then that will be stored in the passed pointer,
 * whereas the return value indicates whether a constant was found or not.
 * The reason for implementing it like this is that some constants map to 0,
 * so it is not possible to tell from the return value alone whether a
 * constant was mapped or not. */
int
parse_function_int_constant(const char *string)
{
	if (startswith("DIR_", string))
		string += 4;

	map("LEFT", DIR_LEFT);
	map("RIGHT", DIR_RIGHT);
	map("UP", DIR_UP);
	map("DOWN", DIR_DOWN);
	map("TOP_LEFT", DIR_LEFT | DIR_UP );
	map("TOP_RIGHT", DIR_RIGHT | DIR_UP);
	map("BOTTOM_LEFT", DIR_LEFT | DIR_DOWN );
	map("BOTTOM_RIGHT", DIR_RIGHT | DIR_DOWN);
	map("TOP_LEFT", DIR_LEFT | DIR_UP );
	map("TOP_RIGHT", DIR_RIGHT | DIR_UP);
	map("BOTTOM_LEFT", DIR_LEFT | DIR_DOWN );
	map("BOTTOM_RIGHT", DIR_RIGHT | DIR_DOWN);
	map("DEGREE_90", DEGREE_90);
	map("DEGREE_180", DEGREE_180);
	map("DEGREE_270", DEGREE_270);
	map("FLIP_HORIZONTAL", FLIP_HORIZONTAL);
	map("FLIP_VERTICAL", FLIP_VERTICAL);
	map("SCALE_DOWN", SCALE_DOWN);
	map("SCALE_FIT", SCALE_FIT);
	map("SCALE_FILL", SCALE_FILL);
	map("SCALE_WIDTH", SCALE_WIDTH);
	map("SCALE_HEIGHT", SCALE_HEIGHT);
	map("SCALE_ZOOM", SCALE_ZOOM);
	map("DRAG_RELATIVE", DRAG_RELATIVE);
	map("DRAG_ABSOLUTE", DRAG_ABSOLUTE);
	map("None", None);
	return 0;
}

#undef map
