#include "interception.h"
#include "utils.h"
#include <windows.h>
#include <math.h>
#include <iostream>

int main()
{
	InterceptionContext context;
	InterceptionDevice device;
	InterceptionStroke stroke;

	raise_process_priority();

	context = interception_create_context();

	// interception_set_filter(context, interception_is_keyboard, INTERCEPTION_FILTER_KEY_DOWN | INTERCEPTION_FILTER_KEY_UP);
	interception_set_filter(context, interception_is_mouse, INTERCEPTION_FILTER_MOUSE_MOVE);


	int
		var_accelMode = 0;

	double
		frameTime_ms = 0,
		dx,
		dy,
		accelSens,
		rate,
		power,
		a,					//Taunty called it 'a' and I'm not creative
		b,					//var_accel/abs(a)
		carryX = 0,
		carryY = 0,
		reducedX = 0,
		reducedY = 0,
		var_sens = 1,
		var_accel = 0,
		var_senscap = 0,
		var_offset = 0,
		var_power = 2,
		var_preScaleX = 1,
		var_preScaleY = 1,
		var_postScaleX = 1,
		var_postScaleY = 1,
		var_angle = 0,
		var_angleSnap = 0,
		var_speedCap = 0,
		pi = 3.141592653589793238462643383279502884197169399375105820974944592307816406,
		hypot,
		angle,
		newangle,
		variableValue;

	bool debugOutput = 0, garbageFile = 0;
	char variableName[24];
	COORD coord;

	HANDLE hConsole;
	hConsole = GetStdHandle(STD_OUTPUT_HANDLE);

	
	CONSOLE_FONT_INFOEX cfi;
	cfi.cbSize = sizeof cfi;
	cfi.nFont = 0;
	cfi.dwFontSize.X = 0;
	cfi.dwFontSize.Y = 14;
	cfi.FontFamily = FF_DONTCARE;
	cfi.FontWeight = FW_NORMAL;
	wcscpy(cfi.FaceName, L"Consolas");
	SetCurrentConsoleFontEx(hConsole, FALSE, &cfi);
	

	coord.X = 80;
	coord.Y = 25;
	SetConsoleScreenBufferSize(hConsole, coord);
	
	SMALL_RECT conSize;

	conSize.Left = 0;
	conSize.Top = 0;
	conSize.Right = coord.X - 1;
	conSize.Bottom = coord.Y - 1;

	SetConsoleWindowInfo(hConsole, TRUE, &conSize);

	SetConsoleTextAttribute(hConsole, 0x0f);
	printf("povohat's interception mouse accel\nAdditional contributions by Sidiouth & _m00se_\n==============================================\n\n");
	SetConsoleTextAttribute(hConsole, 0x08);


	printf("Opening settings file...\n");


	// read variables once at runtime
	FILE *fp;

	if ((fp = fopen("settings.txt", "r+")) == NULL) {
		SetConsoleTextAttribute(hConsole, 0x04);
		printf("* Cannot read from settings file. Using defaults.\n");
		SetConsoleTextAttribute(hConsole, 0x08);
	}
	else
	{
		for (int i = 0; i < 99 && fscanf(fp, "%s = %lf", &variableName, &variableValue) != EOF; i++) {		//Doesn't complain if a line in settings.txt is missing

			if (strcmp(variableName, "AccelMode") == 0)
			{
				var_accelMode = variableValue;
			}
			else if (strcmp(variableName, "Sensitivity") == 0)
			{
				var_sens = variableValue;
			}
			else if (strcmp(variableName, "Acceleration") == 0)
			{
				var_accel = variableValue;
			}
			else if (strcmp(variableName, "SensitivityCap") == 0)
			{
				var_senscap = variableValue;
			}
			else if (strcmp(variableName, "Offset") == 0)
			{
				var_offset = variableValue;
			}
			else if (strcmp(variableName, "Power") == 0)
			{
				var_power = variableValue;
			}
			else if (strcmp(variableName, "Pre-ScaleX") == 0)
			{
				var_preScaleX = variableValue;
			}
			else if (strcmp(variableName, "Pre-ScaleY") == 0)
			{
				var_preScaleY = variableValue;
			}
			else if (strcmp(variableName, "Post-ScaleX") == 0)
			{
				var_postScaleX = variableValue;
			}
			else if (strcmp(variableName, "Post-ScaleY") == 0)
			{
				var_postScaleY = variableValue;
			}
			else if (strcmp(variableName, "AngleAdjustment") == 0)
			{
				var_angle = variableValue;
			}
			else if (strcmp(variableName, "AngleSnapping") == 0)
			{
				var_angleSnap = variableValue;
			}
			else if (strcmp(variableName, "SpeedCap") == 0)
			{
				var_speedCap = variableValue;
			}
			else if (strcmp(variableName, "FancyOutput") == 0)
			{
				if (variableValue != 0) {
					debugOutput = 1;
				}
				
			}
			else
			{
				garbageFile = 1;
			}
		}

		fclose(fp);

	}

	if (garbageFile) {
		SetConsoleTextAttribute(hConsole, 0x04);
		printf("* Your settings.txt has garbage in it which is being ignored\n");
		SetConsoleTextAttribute(hConsole, 0x08);
	}

	printf("\nYour settings are:\n");

	SetConsoleTextAttribute(hConsole, 0x02);
	printf("AccelMode: %i\nSensitivity: %f\nAcceleration: %f\nSensitivity Cap: %f\nOffset: %f\nPower: %f\nPre-Scale: x:%f, y:%f\nPost-Scale: x:%f, y:%f\nAngle Correction: %f\nAngle Snapping: %f\nSpeed Cap: %f\n\n", var_accelMode, var_sens, var_accel, var_senscap, var_offset, var_power, var_preScaleX, var_preScaleY, var_postScaleX, var_postScaleY, var_angle, var_angleSnap, var_speedCap);
	SetConsoleTextAttribute(hConsole, 0x08);


	SetConsoleTextAttribute(hConsole, 0x4f);
	printf(" [CTRL+C] to QUIT ");
	SetConsoleTextAttribute(hConsole, 0x08);

	if (!debugOutput) {
		printf("\n\nSet 'FancyOutput = 1' in settings.txt for realtime data\n(debug use only: may result in some latency)");
	}
	

	LARGE_INTEGER frameTime, oldFrameTime, PCfreq;

	QueryPerformanceCounter(&oldFrameTime);
	QueryPerformanceFrequency(&PCfreq);
	
	//Pre-loop calculations
	a = var_senscap - var_sens;
	b = var_accel / abs(a);
	power = var_power - 1 < 0 ? 0 : var_power - 1;

	while (interception_receive(context, device = interception_wait(context), &stroke, 1) > 0)
	{

		if (interception_is_mouse(device))
		{
			InterceptionMouseStroke &mstroke = *(InterceptionMouseStroke *)&stroke;

			if (!(mstroke.flags & INTERCEPTION_MOUSE_MOVE_ABSOLUTE)) {

				// figure out frametime
				QueryPerformanceCounter(&frameTime);
				frameTime_ms = (double) (frameTime.QuadPart - oldFrameTime.QuadPart) * 1000.0 / PCfreq.QuadPart;
				if (frameTime_ms > 200)
					frameTime_ms = 200;

				// retrieve new mouse data
				dx = (double) mstroke.x;
				dy = (double) mstroke.y;

				// angle correction
				if (var_angle) {
					hypot = sqrt(dx*dx + dy*dy); // convert to polar
					angle = atan2(dy, dx);

					angle += (var_angle * pi / 180); // apply adjustment in radians

					dx = hypot * cos(angle); // convert back to cartesian
					dy = hypot * sin(angle);
				}

				// angle snapping
				if (var_angleSnap) {
					hypot = sqrt(dx*dx + dy*dy); // convert to polar
					newangle = angle = atan2(dy, dx);


					if (fabs(cos(angle)) < (var_angleSnap*pi / 180)) {	// test for vertical
						if (sin(angle) > 0) {
							newangle = pi / 2;
						}
						else {
							newangle = 3 * pi / 2;
						}
					}
					else
						if (fabs(sin(angle)) < (var_angleSnap*pi / 180)) {	// test for horizontal
							if (cos(angle) < 0) {
								newangle = pi;
							}
							else {
								newangle = 0;
							}
						}

					dx = hypot * cos(newangle); // convert back to cartesian
					dy = hypot * sin(newangle);

					if (debugOutput) {

						coord.X = 40;
						coord.Y = 14;
						SetConsoleCursorPosition(hConsole, coord);
						if (angle - newangle != 0) {
							SetConsoleTextAttribute(hConsole, 0x2f);
							printf("Snapped");
						}
						else {
							printf("       ");
						}
						SetConsoleTextAttribute(hConsole, 0x08);

					}
						

				}

				// apply pre-scale
				dx *= var_preScaleX;
				dy *= var_preScaleY;

				// apply speedcap
				if (var_speedCap) {
					rate = sqrt(dx*dx + dy*dy);

					if (debugOutput) {
						coord.X = 40;
						coord.Y = 15;
						SetConsoleCursorPosition(hConsole, coord);
					}

					if (rate >= var_speedCap) {
						dx *= var_speedCap / rate;
						dy *= var_speedCap / rate;
						if (debugOutput) {
							SetConsoleTextAttribute(hConsole, 0x2f);
							printf("Capped");
							SetConsoleTextAttribute(hConsole, 0x08);
						}
					}
					else {
						if (debugOutput) {
							printf("      ");
						}							
					}
				}

				// apply accel
				accelSens = var_sens;							// start with in-game sens so accel calc scales the same
				if (var_accel > 0) {
					rate = sqrt(dx*dx + dy*dy) / frameTime_ms;	// calculate velocity of mouse based on deltas
					rate -= var_offset;							// offset affects the rate that accel sees
					if (rate > 0) {
						switch (var_accelMode) {
						case 0:									//Original InterAccel acceleration
							accelSens += pow((rate*var_accel), power);
							break;
						case 1:									//TauntyArmordillo's natural acceleration
							accelSens += a - (a * exp((-rate*b)));
							break;
						case 2:									//Natural Log acceleration
							accelSens += log((rate*var_accel) + 1);
							break;
						}
					}

					if (debugOutput) {
						coord.X = 40;
						coord.Y = 8;
						SetConsoleCursorPosition(hConsole, coord);
					}

					if (var_senscap > 0 && accelSens >= var_senscap) {
						accelSens = var_senscap;				// clamp post-accel sensitivity at senscap
						if (debugOutput) {
							SetConsoleTextAttribute(hConsole, 0x2f);
							printf("Capped");
						}
					}
					else {
						if (debugOutput) {
							printf("      ");
						}
					}

					if (debugOutput) {
						SetConsoleTextAttribute(hConsole, 0x08);
					}


				}
				accelSens /= var_sens;							// divide by in-game sens as game will multiply it out
				dx *= accelSens;								// apply accel to horizontal
				dy *= accelSens;

				// apply post-scale
				dx *= var_postScaleX;
				dy *= var_postScaleY;

				// add remainder from previous cycle
				dx += carryX;
				dy += carryY;

				// reduce movement to whole number
				reducedX = round(dx);
				reducedY = round(dy);

				// remainder gets passed into next cycle
				carryX = dx - reducedX;
				carryY = dy - reducedY;

				if (debugOutput) {
					coord.X = 0;
					coord.Y = 20;
					SetConsoleCursorPosition(hConsole, coord);
					SetConsoleTextAttribute(hConsole, 0x08);
					printf("input    - X: %05d   Y: %05d\n", mstroke.x, mstroke.y);
					printf("output   - X: %05d   Y: %05d    accel sens: %.3f      \n", (int)reducedX, (int)reducedY, accelSens);
					printf("subpixel - X: %.3f   Y: %.3f    frame time: %.3f      ", carryX, carryY, frameTime_ms);
					SetConsoleTextAttribute(hConsole, 0x08);


					coord.X = 40;
					coord.Y = 7;
					SetConsoleCursorPosition(hConsole, coord);
					if (accelSens > 1) {
						SetConsoleTextAttribute(hConsole, 0x2f);
						printf("Accel +");
					}
					else if (accelSens < 1) {
						SetConsoleTextAttribute(hConsole, 0x4f);
						printf("Accel -");
					}
					else {
						printf("       ");
					}
					SetConsoleTextAttribute(hConsole, 0x08);

				}

				// output new counts
				mstroke.x = (int)reducedX;
				mstroke.y = (int)reducedY;

				oldFrameTime = frameTime;
			}

			interception_send(context, device, &stroke, 1);
		} 
	}

	interception_destroy_context(context);

	return 0;
}
