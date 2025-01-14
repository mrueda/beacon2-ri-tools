#!/usr/bin/env perl
#
#   Script that runs Minion Job Queue System UI
#
#   Last Modified: Feb/01/2022
#
#   Version 2.0.3
#
#   Copyright (C) 2021-2025 Manuel Rueda (manuel.rueda@cnag.eu)
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, see <https://www.gnu.org/licenses/>.
#
#   If this program helps you in your research, please cite.

use Mojolicious::Lite;
plugin Minion => {
    SQLite => 'sqlite:' . app->home->child('minion.db'),
};
plugin 'Minion::Admin', {
    # Host Admin UI at /
    route => app->routes->any('/'),
};
app->start;
