int
width_launcher(Bar *bar, BarArg *a)
{
	int i, x = 0;

	for (i = 0; i < LENGTH(launchers); i++) {
		x += status2dtextlength(launchers[i].name) + lrpad;
	}
	return x;
}

int
draw_launcher(Bar *bar, BarArg *a)
{
	int i, w = 0;;

	for (i = 0; i < LENGTH(launchers); i++) {
		w = status2dtextlength(launchers[i].name);
		drawstatusbar(a, launchers[i].name);
		a->x += w + lrpad;
	}

	return a->x ;
}

int
click_launcher(Bar *bar, Arg *arg, BarArg *a)
{
	int i, x = 0;

	for (i = 0; i < LENGTH(launchers); i++) {
		x += status2dtextlength(launchers[i].name) + lrpad;
		if (a->x < x) {
		    spawn(&launchers[i].command);
		    break;
		}
	}
	return -1;
}
