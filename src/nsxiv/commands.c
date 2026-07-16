/* Copyright 2011-2020 Bert Muennich
 * Copyright 2021-2023 nsxiv contributors
 *
 * This file is a part of nsxiv.
 *
 * nsxiv is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 *
 * nsxiv is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with nsxiv.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "nsxiv.h"

#include "commands.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

extern img_t img;
extern tns_t tns;
extern win_t win;

static bool navigate_to(arg_t n)
{
	if (n >= 0 && n < filecnt && n != fileidx) {
		if (mode == MODE_IMAGE) {
			load_image(n);
		} else if (mode == MODE_THUMB) {
			fileidx = n;
			tns.dirty = true;
		}
		return true;
	}
	return false;
}

bool cg_quit(arg_t status)
{
	unsigned int i;

	if (options->to_stdout && markcnt > 0) {
		for (i = 0; i < (unsigned int)filecnt; i++) {
			if (files[i].flags & FF_MARK)
				printf("%s%c", files[i].name, options->using_null ? '\0' : '\n');
		}
	}
	exit(status);
	return None; /* silence tcc warning */
}

bool cg_pick_quit(arg_t status)
{
	if (options->to_stdout && markcnt == 0)
		printf("%s%c", files[fileidx].name, options->using_null ? '\0' : '\n');
	return cg_quit(status);
}

bool cg_switch_mode(arg_t _)
{
	if (mode == MODE_IMAGE) {
		if (tns.thumbs == NULL)
			tns_init(&tns, files, &filecnt, &fileidx, &win);
		img_close(&img, false);
		reset_timeout(reset_cursor);
		if (img.ss.on) {
			img.ss.on = false;
			reset_timeout(slideshow);
		}
		tns.dirty = true;
		mode = MODE_THUMB;
	} else {
		load_image(fileidx);
		mode = MODE_IMAGE;
	}
	return true;
}

bool cg_toggle_bar(arg_t _)
{
	win_toggle_bar(&win);
	if (mode == MODE_IMAGE)
		img.checkpan = img.dirty = true;
	else
		tns.dirty = true;
	if (win.bar.h > 0)
		open_info();
	else
		close_info();
	return true;
}

bool cg_toggle_invert(arg_t _)
{
	img.invert = !img.invert;
	img_update_color_modifiers(&img);
	if (mode == MODE_THUMB)
		tns.dirty = true;
	return true;
}

bool cg_toggle_fullscreen(arg_t _)
{
	win_toggle_fullscreen(&win);
	/* redraw after next ConfigureNotify event */
	set_timeout(redraw, TO_REDRAW_RESIZE, false);
	if (mode == MODE_IMAGE)
		img.checkpan = img.dirty = true;
	else
		tns.dirty = true;
	return false;
}

bool cg_prefix_external(arg_t _)
{
	handle_key_handler(true);
	return false;
}

bool cg_reload_image(arg_t _)
{
	if (mode == MODE_IMAGE) {
		load_image(fileidx);
	} else {
		win_set_cursor(&win, CURSOR_WATCH);
		if (!tns_load(&tns, fileidx, true, false)) {
			remove_file(fileidx, false);
			tns.dirty = true;
		}
	}
	return true;
}

bool cg_remove_image(arg_t _)
{
	remove_file(fileidx, true);
	if (mode == MODE_IMAGE)
		load_image(fileidx);
	else
		tns.dirty = true;
	return true;
}

bool cg_first(arg_t _)
{
	return navigate_to(0);
}

bool cg_n_or_last(arg_t _)
{
	int n = prefix != 0 && prefix - 1 < filecnt ? prefix - 1 : filecnt - 1;
	return navigate_to(n);
}

bool cg_scroll_screen(arg_t dir)
{
	if (mode == MODE_IMAGE)
		return img_pan(&img, dir, -1);
	else
		return tns_scroll(&tns, dir, true);
}

bool cg_zoom(arg_t d)
{
	if (mode == MODE_THUMB)
		return tns_zoom(&tns, d);
	else
		return img_zoom(&img, d);
}

bool cg_toggle_image_mark(arg_t _)
{
	return mark_image(fileidx, !(files[fileidx].flags & FF_MARK));
}

bool cg_reverse_marks(arg_t _)
{
	int i;

	if (options->dmenu)
		return false;

	for (i = 0; i < filecnt; i++) {
		files[i].flags ^= FF_MARK;
		markcnt += files[i].flags & FF_MARK ? 1 : -1;
	}
	if (mode == MODE_THUMB)
		tns.dirty = true;
	return true;
}

bool cg_mark_range(arg_t _)
{
	int d = markidx < fileidx ? 1 : -1, end, i;
	bool dirty = false, on = !!(files[markidx].flags & FF_MARK);

	for (i = markidx + d, end = fileidx + d; i != end; i += d)
		dirty |= mark_image(i, on);
	return dirty;
}

bool cg_unmark_all(arg_t _)
{
	int i;

	if (options->dmenu)
		return false;

	for (i = 0; i < filecnt; i++)
		files[i].flags &= ~FF_MARK;
	markcnt = 0;
	if (mode == MODE_THUMB)
		tns.dirty = true;
	return true;
}

bool cg_navigate_marked(arg_t n)
{
	int d, i;
	int new = fileidx;

	if (prefix > 0)
		n *= prefix;
	d = n > 0 ? 1 : -1;
	for (i = fileidx + d; n != 0 && i >= 0 && i < filecnt; i += d) {
		if (files[i].flags & FF_MARK) {
			n -= d;
			new = i;
		}
	}
	return navigate_to(new);
}

bool cg_nav_dir(arg_t d)
{
	const int dx = d > 0 ? 1 : -1;
	int i = fileidx + dx, og = fileidx;
	bool again = d < 0;
	size_t sdir_len = strrchr(files[og].path, '/') - files[og].path;

	while (i < filecnt && i >= 0) {
		size_t ddir_len = strrchr(files[i].path, '/') - files[i].path;
		if (sdir_len != ddir_len ||
		    strncmp(files[og].path, files[i].path, sdir_len) != 0)
		{
			if (!again)
				break;
			og = i;
			sdir_len = strrchr(files[og].path, '/') - files[og].path;
			again = false;
		}
		i += dx;
	}
	if (d < 0 && i >= -1)
		++i;

	if (i < filecnt && i >= 0 && fileidx != i) {
		if (mode == MODE_IMAGE) {
			load_image(i);
			return true;
		}

		return tns_move_selection(&tns, d < 0 ? DIR_LEFT : DIR_RIGHT, ABS(i - fileidx));
	}
	return false;
}

static bool change_color_modifier(arg_t d, int *target)
{
	if (!img_change_color_modifier(&img, d * (prefix > 0 ? prefix : 1), target))
		return false;
	if (mode == MODE_THUMB)
		tns.dirty = true;
	return true;
}

bool cg_change_gamma(arg_t d)
{
	return change_color_modifier(d, &img.gamma);
}

bool cg_change_brightness(arg_t d)
{
	return change_color_modifier(d, &img.brightness);
}

bool cg_change_contrast(arg_t d)
{
	return change_color_modifier(d, &img.contrast);
}

bool cg_dmenu_search(arg_t _)
{
	char output[4096];
	int i, rfd, wfd, goto_img = -1;
	ssize_t n;

	if (spawn(&rfd, &wfd, 0, (char **)cfg_get_command("dmenu_search_cmd")) < 0)
		return false;
	for (i = 0; i < filecnt; ++i) {
		dprintf(wfd, "%s\n", files[i].name);
	}
	close(wfd);
	if ((n = read(rfd, output, sizeof output - 1)) > 0) {
		char *e = memchr(output, '\n', n);
		if (e != NULL)
			*e = '\0';
		else
			output[n] = '\0';
		for (i = 0; i < filecnt; ++i) {
			if (STREQ(output, files[i].name)) {
				goto_img = i;
				break;
			}
		}
	}
	close(rfd);

	return navigate_to(goto_img);
}

bool ci_navigate(arg_t n)
{
	if (prefix > 0)
		n *= prefix;
	n += fileidx;

	if (enabled(ImageModeCycle)) {
		n = WRAP(n, 0, filecnt - 1);
	} else {
		n = CLAMP(n, 0, filecnt - 1);
	}

	if (n != fileidx) {
		load_image(n);
		return true;
	}

	return false;
}

bool ci_cursor_navigate(arg_t _)
{
	return ci_navigate(nav_button() - 1);
}

bool ci_alternate(arg_t _)
{
	load_image(alternate);
	return true;
}

bool ci_navigate_frame(arg_t d)
{
	if (prefix > 0)
		d *= prefix;
	return !img.multi.animate && img_frame_navigate(&img, d);
}

bool ci_toggle_animation(arg_t _)
{
	bool dirty = false;

	if (img.multi.cnt > 0) {
		img.multi.animate = !img.multi.animate;
		if (img.multi.animate) {
			dirty = img_frame_animate(&img);
			set_timeout(animate, img.multi.frames[img.multi.sel].delay, true);
		} else {
			reset_timeout(animate);
		}
	}
	return dirty;
}

bool ci_scroll_image(arg_t dir)
{
	return img_pan(&img, dir, prefix);
}

bool ci_scroll_to_center(arg_t _)
{
	return img_pan_center(&img);
}

bool ci_scroll_to_edge(arg_t dir)
{
	return img_pan_edge(&img, dir);
}

bool ci_drag(arg_t drag_mode)
{
	int x, y, ox, oy;
	float px, py;
	XEvent e;

	if ((int)(img.w * img.zoom) <= (int)win.w && (int)(img.h * img.zoom) <= (int)win.h)
		return false;

	win_set_cursor(&win, drag_mode == DRAG_ABSOLUTE ? CURSOR_DRAG_ABSOLUTE : CURSOR_DRAG_RELATIVE);
	win_cursor_pos(&win, &x, &y);
	ox = x;
	oy = y;

	while (true) {
		if (drag_mode == DRAG_ABSOLUTE) {
			px = MIN(MAX(0.0, x - win.w * 0.1), win.w * 0.8) /
			     (win.w * 0.8) * (win.w - img.w * img.zoom);
			py = MIN(MAX(0.0, y - win.h * 0.1), win.h * 0.8) /
			     (win.h * 0.8) * (win.h - img.h * img.zoom);
		} else {
			px = img.x + x - ox;
			py = img.y + y - oy;
		}

		if (img_pos(&img, px, py)) {
			img_render(&img);
			win_draw(&win);
		}
		XMaskEvent(win.env.dpy,
		           ButtonPressMask | ButtonReleaseMask | PointerMotionMask, &e);
		if (e.type == ButtonPress || e.type == ButtonRelease)
			break;
		while (XCheckTypedEvent(win.env.dpy, MotionNotify, &e))
			;
		ox = x;
		oy = y;
		x = e.xmotion.x;
		y = e.xmotion.y;
	}
	set_timeout(reset_cursor, TO_CURSOR_HIDE, true);
	reset_cursor();

	return true;
}

bool ci_set_zoom(arg_t zl)
{
	return img_zoom_to(&img, (prefix ? prefix : zl) / 100.0);
}

bool ci_fit_to_win(arg_t sm)
{
	return img_fit_win(&img, sm);
}

bool ci_rotate(arg_t degree)
{
	img_rotate(&img, degree);
	return true;
}

bool ci_flip(arg_t dir)
{
	img_flip(&img, dir);
	return true;
}

bool ci_toggle_antialias(arg_t _)
{
	img_toggle_antialias(&img);
	return true;
}

bool ci_toggle_alpha(arg_t _)
{
	img.alpha_layer = !img.alpha_layer;
	img.dirty = true;
	return true;
}

bool ci_slideshow(arg_t _)
{
	if (prefix > 0) {
		img.ss.on = true;
		img.ss.delay = prefix * 10;
		set_timeout(slideshow, img.ss.delay * 100, true);
	} else if (img.ss.on) {
		img.ss.on = false;
		reset_timeout(slideshow);
	} else {
		img.ss.on = true;
	}
	return true;
}

bool ct_move_sel(arg_t dir)
{
	return tns_move_selection(&tns, dir, prefix);
}

bool ct_reload_all(arg_t _)
{
	tns_free(&tns);
	tns_init(&tns, files, &filecnt, &fileidx, &win);
	tns.dirty = true;
	return true;
}

bool ct_scroll_thumbnails(arg_t dir)
{
	return tns_scroll(&tns, dir, false);
}

bool ct_drag_mark_image(arg_t _)
{
	int sel;

	if ((sel = tns_translate(&tns, xbutton_ev->x, xbutton_ev->y)) >= 0) {
		XEvent e;
		bool on = (options->dmenu || !(files[sel].flags & FF_MARK));

		while (true) {
			if (sel >= 0 && mark_image(sel, on))
				redraw();
			XMaskEvent(win.env.dpy,
			           ButtonPressMask | ButtonReleaseMask | PointerMotionMask, &e);
			if (e.type == ButtonPress || e.type == ButtonRelease)
				break;
			while (XCheckTypedEvent(win.env.dpy, MotionNotify, &e))
				;
			sel = tns_translate(&tns, e.xbutton.x, e.xbutton.y);
		}
	}

	return false;
}

bool ct_select(arg_t _)
{
	int sel;
	bool dirty = false;
	static Time firstclick;

	if ((sel = tns_translate(&tns, xbutton_ev->x, xbutton_ev->y)) >= 0) {
		if (sel != fileidx) {
			tns_highlight(&tns, fileidx, false);
			tns_highlight(&tns, sel, true);
			fileidx = sel;
			firstclick = xbutton_ev->time;
			dirty = true;
		} else if (xbutton_ev->time - firstclick <= TO_DOUBLE_CLICK) {
			mode = MODE_IMAGE;
			set_timeout(reset_cursor, TO_CURSOR_HIDE, true);
			load_image(fileidx);
			dirty = true;
		} else {
			firstclick = xbutton_ev->time;
		}
	}

	return dirty;
}

/* NOTE(NRK): could be faster with __builtin_clz(), but i've opted for portibility instead.
 * ref: https://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2
 */
static unsigned int next_power_of_2_modmask(unsigned int v)
{
	--v;
	v |= v >> 1;
	v |= v >> 2;
	v |= v >> 4;
	v |= v >> 8;
	v |= v >> 16;
	return v;
}

/* Rejects any baised samples with the bitmask approach described in:
 * https://www.pcg-random.org/posts/bounded-rands.html
 */
bool cg_random_image(arg_t _)
{
	if (filecnt >= 2) {
		int n;
		unsigned int mask = next_power_of_2_modmask(filecnt);
		do {
			n = rand() & mask;
		} while (n >= filecnt || n == fileidx);
		return navigate_to(n);
	}
	return false;
}
