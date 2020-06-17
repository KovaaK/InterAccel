#include "interception.h"
#include "utils.h"
#include <windows.h>
#define _USE_MATH_DEFINES
#include <cmath>
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


	double
		frameTime_ms = 0.0,
		dx,
		dy,
		accelSens,
		rate,
		power,
		carryX = 0.0,
		carryY = 0.0,
		var_sens = 1.0,
		var_accel = 0.0,
		var_senscap = 0.0,
		var_offset = 0.0,
		var_power = 2.0,
		var_preScaleX = 1.0,
		var_preScaleY = 1.0,
		var_postScaleX = 1.0,
		var_postScaleY = 1.0,
		var_angle = 0.0,
		var_angleSnap = 0.0,
		var_speedCap = 0.0,
		hypot,
		angle,
		newangle,
		variableValue;

	bool debugOutput = false, garbageFile = false;
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
	printf("povohat's quake live accel emulator v0.000002\n=============================================\n\n");
	SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);


	printf("Opening settings file...\n");


	// read variables once at runtime
	FILE *fp;

	if ((fp = fopen("settings.txt", "r+")) == NULL) {
		SetConsoleTextAttribute(hConsole, FOREGROUND_RED);
		printf("* Cannot read from settings file. Using defaults.\n");
		SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);
	}
	else
	{
		for (int i = 0; i < 99 && fscanf(fp, "%s = %lf", &variableName, &variableValue) != EOF; i++) {

			if (strcmp(variableName, "Sensitivity") == 0)
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
					debugOutput = true;
				}
				
			}
			else
			{
				garbageFile = true;
			}
		}

		fclose(fp);

	}

	if (garbageFile) {
		SetConsoleTextAttribute(hConsole, FOREGROUND_RED);
		printf("* Your settings.txt has garbage in it which is being ignored\n");
		SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);
	}

	printf("\nYour settings are:\n");

	SetConsoleTextAttribute(hConsole, FOREGROUND_GREEN);
	printf("Sensitivity: %f\nAcceleration: %f\nSensitivity Cap: %f\nOffset: %f\nPower: %f\nPre-Scale: x:%f, y:%f\nPost-Scale: x:%f, y:%f\nAngle Correction: %f\nAngle Snapping: %f\nSpeed Cap: %f\n\n", var_sens, var_accel, var_senscap, var_offset, var_power, var_preScaleX, var_preScaleY, var_postScaleX, var_postScaleY, var_angle, var_angleSnap, var_speedCap);
	SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);


	SetConsoleTextAttribute(hConsole, 0x4f);
	printf(" [CTRL+C] to QUIT ");
	SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);

	if (!debugOutput) {
		printf("\n\nSet 'FancyOutput = 1' in settings.txt for realtime data\n(debug use only: may result in some latency)");
	}
	

	LARGE_INTEGER frameTime, oldFrameTime, PCfreq;

	QueryPerformanceCounter(&oldFrameTime);
	QueryPerformanceFrequency(&PCfreq);

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

					angle += (var_angle * M_PI / 180); // apply adjustment in radians

					dx = hypot * cos(angle); // convert back to cartesian
					dy = hypot * sin(angle);
				}

				// angle snapping
				if (var_angleSnap) {
					hypot = sqrt(dx*dx + dy*dy); // convert to polar
					newangle = angle = atan2(dy, dx);


					if (fabs(cos(angle)) < (var_angleSnap*M_PI / 180)) {	// test for vertical
						if (sin(angle) > 0) {
							newangle = M_PI / 2;
						}
						else {
							newangle = 3 * M_PI / 2;
						}
					}
					else
						if (fabs(sin(angle)) < (var_angleSnap*M_PI / 180)) {	// test for horizontal
							if (cos(angle) < 0) {
								newangle = M_PI;
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
						SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);

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
							SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);
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
						rate *= var_accel;
						power = var_power - 1;
						if (power < 0) {
							power = 0;							// clamp power at lower bound of 0
						}
						accelSens += exp(power * log(rate));		// acceptable substitute for the missing pow() function
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
						SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);
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

				// remainder gets passed into next cycle
				carryX = dx - floor(dx);
				carryY = dy - floor(dy);

				if (debugOutput) {
					coord.X = 0;
					coord.Y = 20;
					SetConsoleCursorPosition(hConsole, coord);
					SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);
					printf("input    - X: %05d   Y: %05d\n", mstroke.x, mstroke.y);
					printf("output   - X: %05d   Y: %05d    accel sens: %.3f      \n", (int)floor(dx), (int)floor(dy), accelSens);
					printf("subpixel - X: %.3f   Y: %.3f    frame time: %.3f      ", carryX, carryY, frameTime_ms);
					SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);


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
					SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);

				}

				// output new counts
				mstroke.x = (int)floor(dx);
				mstroke.y = (int)floor(dy);

				oldFrameTime = frameTime;
			}

			interception_send(context, device, &stroke, 1);
		} 
	}

	interception_destroy_context(context);

	return 0;
}
