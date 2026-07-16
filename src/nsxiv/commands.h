#ifndef COMMANDS_H
#define COMMANDS_H
#include <stdbool.h>

/* global */
bool cg_change_gamma(arg_t);
bool cg_change_brightness(arg_t);
bool cg_change_contrast(arg_t);
bool cg_dmenu_search(arg_t _);
bool cg_first(arg_t);
bool cg_mark_range(arg_t);
bool cg_n_or_last(arg_t);
bool cg_navigate_marked(arg_t);
bool cg_nav_dir(arg_t);
bool cg_prefix_external(arg_t);
bool cg_quit(arg_t);
bool cg_pick_quit(arg_t);
bool cg_random_image(arg_t);
bool cg_reload_image(arg_t);
bool cg_remove_image(arg_t);
bool cg_reverse_marks(arg_t);
bool cg_scroll_screen(arg_t);
bool cg_switch_mode(arg_t);
bool cg_toggle_bar(arg_t);
bool cg_toggle_invert(arg_t);
bool cg_toggle_fullscreen(arg_t);
bool cg_toggle_image_mark(arg_t);
bool cg_unmark_all(arg_t);
bool cg_zoom(arg_t);
/* image mode */
bool ci_alternate(arg_t);
bool ci_cursor_navigate(arg_t);
bool ci_drag(arg_t);
bool ci_fit_to_win(arg_t);
bool ci_flip(arg_t);
bool ci_navigate(arg_t);
bool ci_navigate_frame(arg_t);
bool ci_rotate(arg_t);
bool ci_scroll_image(arg_t);
bool ci_scroll_to_center(arg_t);
bool ci_scroll_to_edge(arg_t);
bool ci_set_zoom(arg_t);
bool ci_slideshow(arg_t);
bool ci_toggle_alpha(arg_t);
bool ci_toggle_animation(arg_t);
bool ci_toggle_antialias(arg_t);
/* thumbnails mode */
bool ct_move_sel(arg_t);
bool ct_reload_all(arg_t);
bool ct_scroll_thumbnails(arg_t);
bool ct_drag_mark_image(arg_t);
bool ct_select(arg_t);

#endif /* COMMANDS_H */
