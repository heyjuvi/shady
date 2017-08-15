/* main.vala
 *
 * Copyright (C) 2017 misterdanb
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

int main(string[] args)
{
	print("TEEEEEST\n");
	print("TEEEEEST\n");
	print("TEEEEEST\n");

	X.init_threads();
	Environment.set_variable("EGL_LOG_LEVEL","fatal",true);
	return new Shady.App().run(args);
}
