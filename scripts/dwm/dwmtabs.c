/* dwmtabs - Tab management for dwm via tabbed reparenting.
 *
 * Replaces the bash + xdotool + xprop + xrandr + xwininfo + awk script
 * with a single libX11 + Xinerama tool. Spawns and finds tabbed
 * containers (class "dwm-tabbed"), reparents the focused window
 * into / out of them.
 *
 * Usage: dwmtabs {attach|detach|create}
 *   attach  put focused window into a container on this monitor
 *           (creating one if none exists)
 *   detach  remove focused window (or first child of focused
 *           container) back to root; kill empty containers
 *   create  spawn an empty container, print its window id
 *
 * Build: cc -std=c99 -pedantic -Wall -Os -o dwmtabs dwmtabs.c \
 *           -lX11 -lXinerama
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/Xinerama.h>

#define CLASS_NAME  "dwm-tabbed"
#define TABBED_BIN  "tabbed"
#define POLL_TRIES  40
#define POLL_USEC   25000

static Display *dpy;
static Window   root;

static void
die(const char *msg)
{
	fprintf(stderr, "dwmtabs: %s\n", msg);
	exit(1);
}

/* Match against either the instance (res_name) or class (res_class)
 * field of WM_CLASS. tabbed -n sets the instance field, so we'd miss
 * if we only checked res_class. */
static int
has_class(Window w, const char *cls)
{
	XClassHint hint = {0};
	int match = 0;
	if (!XGetClassHint(dpy, w, &hint))
		return 0;
	if ((hint.res_name  && strcmp(hint.res_name,  cls) == 0) ||
	    (hint.res_class && strcmp(hint.res_class, cls) == 0))
		match = 1;
	if (hint.res_name)  XFree(hint.res_name);
	if (hint.res_class) XFree(hint.res_class);
	return match;
}

/* Active = the WM-managed top-level window, via _NET_ACTIVE_WINDOW
 * on root. XGetInputFocus would return whatever sub-widget has focus
 * inside an app (e.g., a Gtk widget inside Thunar). */
static Window
get_active(void)
{
	Atom net_active = XInternAtom(dpy, "_NET_ACTIVE_WINDOW", True);
	if (net_active == None)
		return 0;
	Atom actual_type;
	int actual_format;
	unsigned long nitems, bytes_after;
	unsigned char *prop = NULL;
	if (XGetWindowProperty(dpy, root, net_active, 0, 1, False,
	                       XA_WINDOW, &actual_type, &actual_format,
	                       &nitems, &bytes_after, &prop) != Success || !prop)
		return 0;
	Window w = *(Window *)prop;
	XFree(prop);
	if (w == None || w == PointerRoot)
		return 0;
	return w;
}

/* Translate window's top-left to root-relative coordinates. */
static int
win_root_xy(Window w, int *x, int *y)
{
	Window child, dummy_root;
	int dx, dy;
	unsigned int dw, dh, db, dd;
	if (!XGetGeometry(dpy, w, &dummy_root, &dx, &dy, &dw, &dh, &db, &dd))
		return 0;
	return XTranslateCoordinates(dpy, w, root, 0, 0, x, y, &child);
}

/* Find Xinerama monitor containing the center of window w.
 * Returns 1 and fills *mx,*my,*mw,*mh on success. */
static int
get_monitor(Window w, int *mx, int *my, int *mw, int *mh)
{
	int x, y;
	Window dummy_root, child;
	unsigned int width, height, b, d;
	if (!XGetGeometry(dpy, w, &dummy_root, &x, &y, &width, &height, &b, &d))
		return 0;
	XTranslateCoordinates(dpy, w, root, 0, 0, &x, &y, &child);
	int cx = x + (int)width / 2;
	int cy = y + (int)height / 2;

	int n = 0;
	XineramaScreenInfo *info = XineramaQueryScreens(dpy, &n);
	if (info) {
		for (int i = 0; i < n; i++) {
			if (cx >= info[i].x_org && cx < info[i].x_org + info[i].width &&
			    cy >= info[i].y_org && cy < info[i].y_org + info[i].height) {
				*mx = info[i].x_org; *my = info[i].y_org;
				*mw = info[i].width; *mh = info[i].height;
				XFree(info);
				return 1;
			}
		}
		XFree(info);
	}
	/* Fallback: full screen */
	*mx = 0; *my = 0;
	*mw = DisplayWidth(dpy, DefaultScreen(dpy));
	*mh = DisplayHeight(dpy, DefaultScreen(dpy));
	return 1;
}

/* Topmost viewable child of `parent` (= the active tab inside a tabbed
 * container). XQueryTree returns children bottom-to-top, so iterate
 * back-to-front. Tabbed unmaps inactive tabs, so map_state filters them
 * out. Used by detach so the user-visible tab gets removed, not just
 * children[0] (which is the oldest, not necessarily the active one). */
static Window
find_active_child(Window parent)
{
	Window r1, r2, *children = NULL;
	unsigned int n = 0;
	Window result = 0;
	if (!XQueryTree(dpy, parent, &r1, &r2, &children, &n))
		return 0;
	for (int i = (int)n - 1; i >= 0; i--) {
		XWindowAttributes wa;
		if (XGetWindowAttributes(dpy, children[i], &wa) &&
		    wa.map_state == IsViewable) {
			result = children[i];
			break;
		}
	}
	if (children) XFree(children);
	return result;
}

/* First viewable container with our class on the given monitor rect. */
static Window
find_tab(int mx, int my, int mw, int mh)
{
	Window r1, r2, *children = NULL;
	unsigned int n = 0;
	Window result = 0;
	if (!XQueryTree(dpy, root, &r1, &r2, &children, &n))
		return 0;
	for (unsigned int i = 0; i < n; i++) {
		XWindowAttributes wa;
		int x, y;
		if (!XGetWindowAttributes(dpy, children[i], &wa))
			continue;
		if (wa.map_state != IsViewable)
			continue;
		if (!has_class(children[i], CLASS_NAME))
			continue;
		if (!win_root_xy(children[i], &x, &y))
			continue;
		if (x >= mx && x < mx + mw && y >= my && y < my + mh) {
			result = children[i];
			break;
		}
	}
	if (children) XFree(children);
	return result;
}

/* Spawn `tabbed -d -c -n dwm-tabbed`, read xid from its stdout.
 * tabbed daemonizes after printing its window id. */
static Window
create_tab(void)
{
	int p[2];
	pid_t pid;
	if (pipe(p) < 0)
		return 0;
	if ((pid = fork()) < 0) {
		close(p[0]); close(p[1]);
		return 0;
	}
	if (pid == 0) {
		close(p[0]);
		dup2(p[1], 1);
		close(p[1]);
		execlp(TABBED_BIN, TABBED_BIN, "-d", "-c", "-n", CLASS_NAME, (char *)0);
		_exit(127);
	}
	close(p[1]);
	char buf[64] = {0};
	int n = read(p[0], buf, sizeof(buf) - 1);
	close(p[0]);
	waitpid(pid, NULL, 0);
	if (n <= 0)
		return 0;
	Window w = (Window)strtoul(buf, NULL, 0);
	if (!w)
		return 0;

	/* Poll until viewable so reparent doesn't race. */
	for (int i = 0; i < POLL_TRIES; i++) {
		XWindowAttributes wa;
		if (XGetWindowAttributes(dpy, w, &wa) && wa.map_state == IsViewable)
			return w;
		usleep(POLL_USEC);
	}
	return w;
}

static void
reparent_into(Window src, Window dst)
{
	XUnmapWindow(dpy, src);
	XSync(dpy, False);
	XReparentWindow(dpy, src, dst, 0, 0);
	XMapWindow(dpy, src);
	XSync(dpy, False);
	XSetInputFocus(dpy, dst, RevertToParent, CurrentTime);
}

static int
cmd_attach(void)
{
	Window src = get_active();
	if (!src) {
		fprintf(stderr, "no focused window\n");
		return 1;
	}
	if (has_class(src, CLASS_NAME))
		return 0; /* already a container */

	int mx, my, mw, mh;
	if (!get_monitor(src, &mx, &my, &mw, &mh)) {
		fprintf(stderr, "could not determine monitor\n");
		return 1;
	}
	Window dst = find_tab(mx, my, mw, mh);
	if (!dst) {
		dst = create_tab();
		if (!dst) {
			fprintf(stderr, "could not create tab container\n");
			return 1;
		}
	}
	reparent_into(src, dst);
	return 0;
}

static int
cmd_detach(void)
{
	Window src = get_active();
	if (!src) {
		fprintf(stderr, "no focused window\n");
		return 1;
	}

	Window parent = 0, child = 0, r1, r2, *children = NULL;
	unsigned int n = 0;

	if (has_class(src, CLASS_NAME)) {
		/* Focused IS the container — detach the visible (active) tab.
		 * Note: previously this used children[0] which is the oldest
		 * tab, not the one the user is looking at. */
		parent = src;
		child = find_active_child(parent);
	} else {
		/* Focused is a child — its parent should be the container. */
		if (!XQueryTree(dpy, src, &r1, &parent, &children, &n)) {
			fprintf(stderr, "could not query tree\n");
			return 1;
		}
		if (children) { XFree(children); children = NULL; }
		if (!has_class(parent, CLASS_NAME)) {
			fprintf(stderr, "not in a tab container\n");
			return 1;
		}
		child = src;
	}

	if (!child) {
		XDestroyWindow(dpy, parent);
		XSync(dpy, False);
		return 0;
	}

	XUnmapWindow(dpy, child);
	XSync(dpy, False);
	XReparentWindow(dpy, child, root, 0, 0);
	XMapWindow(dpy, child);
	XSync(dpy, False);
	XSetInputFocus(dpy, child, RevertToParent, CurrentTime);

	/* Kill the container if empty. */
	if (XQueryTree(dpy, parent, &r1, &r2, &children, &n)) {
		if (n == 0)
			XDestroyWindow(dpy, parent);
		if (children) XFree(children);
	}
	XSync(dpy, False);
	return 0;
}

int
main(int argc, char *argv[])
{
	const char *cmd = argc > 1 ? argv[1] : "attach";
	int rc;

	dpy = XOpenDisplay(NULL);
	if (!dpy) die("cannot open display");
	root = DefaultRootWindow(dpy);

	if      (strcmp(cmd, "attach") == 0) rc = cmd_attach();
	else if (strcmp(cmd, "detach") == 0) rc = cmd_detach();
	else if (strcmp(cmd, "create") == 0) {
		Window w = create_tab();
		if (w) { printf("0x%lx\n", w); rc = 0; }
		else   rc = 1;
	}
	else {
		fprintf(stderr, "usage: %s {attach|detach|create}\n", argv[0]);
		rc = 1;
	}

	XCloseDisplay(dpy);
	return rc;
}
