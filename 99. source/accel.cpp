#include "interception.h"
#include <windows.h>
#define _USE_MATH_DEFINES
#include <cmath>
#include <iostream>

int main() {
	InterceptionContext context { interception_create_context() };
	InterceptionDevice device;
	InterceptionStroke stroke;

	SetPriorityClass(GetCurrentProcess(), HIGH_PRIORITY_CLASS);

	interception_set_filter(context, interception_is_mouse, INTERCEPTION_FILTER_MOUSE_MOVE);

	struct AccelSettings {
		double sens { 1.0 };
		double accel { 0.0 };
		double senscap { 0.0 };
		double offset { 0.0 };
		double power { 2.0 };
		double preScaleX { 1.0 };
		double preScaleY { 1.0 };
		double postScaleX { 1.0 };
		double postScaleY { 1.0 };
		double angle { 0.0 };
		double angleSnap { 0.0 };
		double speedCap { 0.0 };
	} settings;

	double
		frameTime_ms { 0.0 },
		dx,
		dy,
		accelSens,
		rate,
		power,
		carryX { 0.0 },
		carryY { 0.0 },
		angle,
		newangle,
		variableValue;

	HANDLE hConsole { GetStdHandle(STD_OUTPUT_HANDLE) };

	
	CONSOLE_FONT_INFOEX cfi {
		sizeof(cfi),
		0,
		{ 0, 14 },
		FF_DONTCARE,
		FW_NORMAL,
		L"Consolas"
	};
	SetCurrentConsoleFontEx(hConsole, FALSE, &cfi);
	
	COORD coord { 80, 25 };
	SetConsoleScreenBufferSize(hConsole, coord);
	
	SMALL_RECT conSize {
		0,
		0,
		static_cast<SHORT>(coord.X - 1),
		static_cast<SHORT>(coord.Y - 1)
	};
	SetConsoleWindowInfo(hConsole, TRUE, &conSize);

	SetConsoleTextAttribute(hConsole, 0x0f);
	printf("povohat's quake live accel emulator v0.000002\n=============================================\n\n");
	SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);


	printf("Opening settings file...\n");


	// read variables once at runtime
	FILE *fp;
	bool debugOutput { false }, garbageFile { false };
	char variableName[24];
	if ((fp = fopen("settings.txt", "r+")) == nullptr) {
		SetConsoleTextAttribute(hConsole, FOREGROUND_RED);
		printf("* Cannot read from settings file. Using defaults.\n");
		SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);
	} else {
		for (int i { 0 }; i < 99 && fscanf(fp, "%s = %lf", &variableName, &variableValue) != EOF; ++i) {

			if (strcmp(variableName, "Sensitivity") == 0) {
				settings.sens = variableValue;
			} else if (strcmp(variableName, "Acceleration") == 0) {
				settings.accel = variableValue;
			} else if (strcmp(variableName, "SensitivityCap") == 0) {
				settings.senscap = variableValue;
			} else if (strcmp(variableName, "Offset") == 0) {
				settings.offset = variableValue;
			} else if (strcmp(variableName, "Power") == 0) {
				settings.power = variableValue;
			} else if (strcmp(variableName, "Pre-ScaleX") == 0) {
				settings.preScaleX = variableValue;
			} else if (strcmp(variableName, "Pre-ScaleY") == 0) {
				settings.preScaleY = variableValue;
			} else if (strcmp(variableName, "Post-ScaleX") == 0) {
				settings.postScaleX = variableValue;
			} else if (strcmp(variableName, "Post-ScaleY") == 0) {
				settings.postScaleY = variableValue;
			} else if (strcmp(variableName, "AngleAdjustment") == 0) {
				settings.angle = variableValue;
			} else if (strcmp(variableName, "AngleSnapping") == 0) {
				settings.angleSnap = variableValue;
			} else if (strcmp(variableName, "SpeedCap") == 0) {
				settings.speedCap = variableValue;
			} else if (strcmp(variableName, "FancyOutput") == 0) {
				if (variableValue != 0) {
					debugOutput = true;
				}
			} else {
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
	printf(
		"Sensitivity: %f\n"
		"Acceleration: %f\n"
		"Sensitivity Cap: %f\n"
		"Offset: %f\n"
		"Power: %f\n"
		"Pre-Scale: x:%f, y:%f\n"
		"Post-Scale: x:%f, y:%f\n"
		"Angle Correction: %f\n"
		"Angle Snapping: %f\n"
		"Speed Cap: %f\n\n",
		settings.sens,
		settings.accel,
		settings.senscap,
		settings.offset,
		settings.power,
		settings.preScaleX,
		settings.preScaleY,
		settings.postScaleX,
		settings.postScaleY,
		settings.angle,
		settings.angleSnap,
		settings.speedCap
	);
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

	while (interception_receive(context, device = interception_wait(context), &stroke, 1) > 0) {

		if (interception_is_mouse(device)) {
			InterceptionMouseStroke &mstroke { *(InterceptionMouseStroke *)&stroke };

			if (!(mstroke.flags & INTERCEPTION_MOUSE_MOVE_ABSOLUTE)) {

				// figure out frametime
				QueryPerformanceCounter(&frameTime);
				frameTime_ms = (double) (frameTime.QuadPart - oldFrameTime.QuadPart) * 1000.0 / PCfreq.QuadPart;
				if (frameTime_ms > 200.0) {
					frameTime_ms = 200.0;
				}

				// retrieve new mouse data
				dx = (double) mstroke.x;
				dy = (double) mstroke.y;

				// angle correction
				if (settings.angle) {
					angle = atan2(dy, dx);

					angle += (settings.angle * M_PI / 180.0); // apply adjustment in radians

					dx = hypot(dx, dy) * cos(angle); // convert back to cartesian
					dy = hypot(dx, dy) * sin(angle);
				}

				// angle snapping
				if (settings.angleSnap) {
					newangle = angle = atan2(dy, dx);


					if (fabs(cos(angle)) < (settings.angleSnap * M_PI / 180.0)) {	// test for vertical
						if (sin(angle) > 0.0) {
							newangle = M_PI / 2.0;
						} else {
							newangle = 3.0 * M_PI / 2.0;
						}
					} else {
						if (fabs(sin(angle)) < (settings.angleSnap * M_PI / 180.0)) {	// test for horizontal
							if (cos(angle) < 0.0) {
								newangle = M_PI;
							} else {
								newangle = 0.0;
							}
						}
					}
					dx = hypot(dx, dy) * cos(newangle); // convert back to cartesian
					dy = hypot(dx, dy) * sin(newangle);

					if (debugOutput) {
						coord = { 40, 14 };
						SetConsoleCursorPosition(hConsole, coord);
						if (angle - newangle != 0.0) {
							SetConsoleTextAttribute(hConsole, 0x2f);
							printf("Snapped");
						} else {
							printf("       ");
						}
						SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);

					}
						

				}

				// apply pre-scale
				dx *= settings.preScaleX;
				dy *= settings.preScaleY;

				// apply speedcap
				if (settings.speedCap) {
					rate = hypot(dx, dy);

					if (debugOutput) {
						coord = { 40, 15 };
						SetConsoleCursorPosition(hConsole, coord);
					}

					if (rate >= settings.speedCap) {
						dx *= settings.speedCap / rate;
						dy *= settings.speedCap / rate;
						if (debugOutput) {
							SetConsoleTextAttribute(hConsole, 0x2f);
							printf("Capped");
							SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);
						}
					} else {
						if (debugOutput) {
							printf("      ");
						}							
					}
				}

				// apply accel
				accelSens = settings.sens;							// start with in-game sens so accel calc scales the same
				if (settings.accel > 0.0) {
					rate = hypot(dx, dy) / frameTime_ms;	// calculate velocity of mouse based on deltas
					rate -= settings.offset;							// offset affects the rate that accel sees
					if (rate > 0.0) {
						rate *= settings.accel;
						power = settings.power - 1.0;
						if (power < 0.0) {
							power = 0.0;							// clamp power at lower bound of 0
						}
						accelSens += pow(rate, power);
					}

					if (debugOutput) {
						coord = { 40, 8 };
						SetConsoleCursorPosition(hConsole, coord);
					}

					if (settings.senscap > 0.0 && accelSens >= settings.senscap) {
						accelSens = settings.senscap;				// clamp post-accel sensitivity at senscap
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
				accelSens /= settings.sens;							// divide by in-game sens as game will multiply it out
				dx *= accelSens;								// apply accel to horizontal
				dy *= accelSens;

				// apply post-scale
				dx *= settings.postScaleX;
				dy *= settings.postScaleY;

				// add remainder from previous cycle
				dx += carryX;
				dy += carryY;

				// remainder gets passed into next cycle
				carryX = dx - floor(dx);
				carryY = dy - floor(dy);

				if (debugOutput) {
					coord = { 0, 20 };
					SetConsoleCursorPosition(hConsole, coord);
					SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);
					printf("input    - X: %05d\tY: %05d\n", mstroke.x, mstroke.y);
					printf("output   - X: %05d\tY: %05d\taccel sens: %.3f\n", (int)floor(dx), (int)floor(dy), accelSens);
					printf("subpixel - X: %.3f\tY: %.3f\tframe time: %.3f\n", carryX, carryY, frameTime_ms);
					SetConsoleTextAttribute(hConsole, FOREGROUND_INTENSITY);


					coord = { 40, 7 };
					SetConsoleCursorPosition(hConsole, coord);
					if (accelSens > 1.0) {
						SetConsoleTextAttribute(hConsole, 0x2f);
						printf("Accel +");
					} else if (accelSens < 1.0) {
						SetConsoleTextAttribute(hConsole, 0x4f);
						printf("Accel -");
					} else {
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
}
