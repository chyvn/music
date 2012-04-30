// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * Copyright (c) 2012 Noise Developers
 *
 * This is a free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

namespace BeatBox.UI {

    /**
     * @deprecated. Since GTK+ 3.0, the align and margin properties will do the trick
     */
    public Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
        message ("wrap_alignment is deprecated. Please don't use it in new code");

        var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
        alignment.top_padding = top;
        alignment.right_padding = right;
        alignment.bottom_padding = bottom;
        alignment.left_padding = left;

        alignment.add (widget);
        return alignment;
    }

    /**
     * elementaryOS fonts
     * TODO: Add special cases for when not using elementaryOS
     */

    public enum TextStyle {
        TITLE,
        H1,
        H2,
        H3
    }

	const string TITLE_STYLESHEET = """
		.title { font: raleway 36; }
	""";

	const string H1_STYLESHEET = """
		.h1 { font: open sans bold 24; }
	""";

	const string H2_STYLESHEET = """
		.h2 { font: open sans light 18; }
	""";

	const string H3_STYLESHEET = """
		.h3 { font: open sans bold 12; }
	""";

    public void apply_style_to_label (Gtk.Label label, TextStyle text_style) {
        var style_provider = new Gtk.CssProvider ();
        var style_context = label.get_style_context ();

        try {
            switch (text_style) {
                case TextStyle.TITLE:
                    style_provider.load_from_data (TITLE_STYLESHEET, -1);
                    style_context.add_class ("title");
                    break;
                case TextStyle.H1:
                    style_provider.load_from_data (H1_STYLESHEET, -1);
                    style_context.add_class ("h1");
                    break;
                case TextStyle.H2:
                    style_provider.load_from_data (H2_STYLESHEET, -1);
                    style_context.add_class ("h2");
                    break;
                case TextStyle.H3:
                    style_provider.load_from_data (H3_STYLESHEET, -1);
                    style_context.add_class ("h3");
                    break;
            }
        }
        catch (Error err) {
            warning ("Couldn't apply style to label: %s", err.message);
            return;
        }

        style_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}

