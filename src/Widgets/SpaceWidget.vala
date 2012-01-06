/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski and Victor Eduardo for
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

using Gtk;
using Gee;

public class SpaceWidget : Gtk.ScrolledWindow {

    public signal void sync_clicked();
    public signal void cancel_clicked();

    public static CssProvider style_provider;

    public enum ItemColor {
        BLUE,
        ORANGE,
        GREEN,
        RED,
        PURPLE,
        GREY
    }

    private enum ItemPosition {
        START,
        END
    }

    private const string WIDGET_STYLE = """
        .SpaceWidgetBase {
            background-image: -gtk-gradient (linear, left top, left bottom,
                                             from (shade (#e6e6e6, 0.96)),
                                             color-stop (0.5, alpha (shade (#e6e6e6, 1.1) , 0.7)),
                                             to (shade (#f7f7f7, 1.04)));
            border-width: 0;
            border-style: none;
            border-radius: 0;
            padding: 0;
        }

        .SpaceBarItem,
        .SpaceBarFullItem,
        .SpaceBarItem:nth-child(first),
        .SpaceBarItem:nth-child(last) {
            -unico-inner-stroke-width: 0;
            -unico-outer-stroke-width: 0;

            -unico-border-gradient: -gtk-gradient (linear, left top, left bottom,
                                                   from (alpha (#fff, 0.5)),
                                                   to (alpha (#fff, 0.0)));

            -unico-outer-stroke-gradient: -gtk-gradient (linear, left top, left bottom,
                                                         from (alpha (#000, 0.03)),
                                                         to (alpha (#000, 0.08)));
        }

        .SpaceBarItem {
            border-radius: 0 0 0 0;
        }

        .SpaceBarFullItem {
            border-radius: 300 300 300 300;
        }

        .SpaceBarItem:nth-child(first) {
            border-radius: 300 0 0 300;
        }

        .SpaceBarItem:nth-child(last) {
            border-radius: 0 300 300 0;
        }

        .LegendItem {
            border-radius: 100 100 100 100;

            -unico-inner-stroke-width: 0;
            -unico-outer-stroke-width: 1;

            -GtkButton-default-border           : 0;
            -GtkButton-image-spacing            : 0;
            -GtkButton-inner-border             : 0;
            -GtkButton-interior-focus           : false;


            -unico-border-gradient: -gtk-gradient (linear, left top, left bottom,
                                                   from (alpha (#fff, 0.9)),
                                                   to (alpha (#fff, 0.5)));

            -unico-outer-stroke-gradient: -gtk-gradient (linear, left top, left bottom,
                                                         from (alpha (#000, 0.04)),
                                                         to (alpha (#000, 0.12)));
        }

        .blue {
            background-image: -gtk-gradient (linear,
                                             left top, left bottom,
                                             from (shade (#4b91dd, 1.10) ),
                                             to (#4b91dd));
        }

        .orange {
            background-image: -gtk-gradient (linear,
                                             left top, left bottom,
                                             from (shade (#eb713f, 1.10)),
                                             to (#eb713f));
        }

        .green {
            background-image: -gtk-gradient (linear,
                                             left top, left bottom,
                                             from (shade (#408549, 1.05)),
                                             to (#408549));
        }

        .purple {
            background-image: -gtk-gradient (linear,
                                           left top, left bottom,
                                           from (shade (#a64067, 1.05)),
                                           to (#a64067));
        }

        .red {
            background-image: -gtk-gradient (linear,
                                               left top, left bottom,
                                               from (shade (#ba393e, 1.05)),
                                               to (#ba393e));
        }

        .grey {
            background-image: -gtk-gradient (linear,
                                               left top, left bottom,
                                               from (shade (#d5d3d1, 1.05)),
                                               to (#d5d3d1));
        }

    """;

    private const int DEFAULT_HEIGHT = 200;
    private const int DEFAULT_WIDTH = 450;
    private const int DEFAULT_PADDING = 10;

    private HashMap<int, SpaceWidgetItem> items;

    private double total_size;
    private double free_space_size;

    private bool single_item_visible;

    private EventBox widget;

    private Box legend_wrapper;
    private Box bar_wrapper;
    private Box full_bar_wrapper;
    private SpaceWidgetBarFullItem full_bar_item;

    private Button action_button;
    private const string SYNC_BUTTON_TEXT = "Sync";
    private const string CANCEL_BUTTON_TEXT = "Cancel";

    public SpaceWidget (double size) {
        // Wrapper properties
        this.set_shadow_type(Gtk.ShadowType.NONE);
        this.min_content_width = DEFAULT_WIDTH;
        this.min_content_height = DEFAULT_HEIGHT;

        widget = new Gtk.EventBox();

        this.set_policy(PolicyType.AUTOMATIC, PolicyType.NEVER);
        this.add_with_viewport(widget);

        style_provider = new CssProvider();

        try  {
            style_provider.load_from_data (WIDGET_STYLE, -1);
        } catch (Error e) {
            stderr.printf ("\nSpaceWidget: Couldn't load style provider.\n");
        }

        widget.get_style_context().add_class("SpaceWidgetBase");
        widget.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);

        var padding = new Box (Orientation.VERTICAL, 0);
        legend_wrapper = new Box (Orientation.HORIZONTAL, 5);
        var top_box = new Box (Orientation.HORIZONTAL, 0);

        // Adding left and right spacing
        top_box.pack_start (new Box (Orientation.HORIZONTAL, 0), true, true, 0);
        top_box.pack_end (new Box (Orientation.HORIZONTAL, 0), true, true, 0);

        // Adding legend
        top_box.pack_start (legend_wrapper, false, true, 0);

        bar_wrapper = new Box (Orientation.HORIZONTAL, 0);
        full_bar_wrapper = new Box (Orientation.HORIZONTAL, 0);
        full_bar_wrapper.set_no_show_all (true);
        full_bar_wrapper.hide ();

        var bottom_box = new Box (Orientation.HORIZONTAL, 0);

        // Adding left and right spacing
        bottom_box.pack_start (new Box (Orientation.HORIZONTAL, 0), true, true, 0);
        bottom_box.pack_end (new Box (Orientation.HORIZONTAL, 0), true, true, 0);

        // Adding bar
        bottom_box.pack_start (bar_wrapper, false, true, 0);
        bottom_box.pack_start (full_bar_wrapper, false, true, 0);

        var left_box = new Box (Orientation.VERTICAL, 3);
        left_box.pack_start (top_box, true, false, 0);
        left_box.pack_end (bottom_box, true, false, 0);

        action_button = new Button.with_label (SYNC_BUTTON_TEXT);
        action_button.set_size_request (90, -1);

        action_button.clicked.connect ( ()=> {
            switch (action_button.get_label()) {
                case CANCEL_BUTTON_TEXT:
                    reset_action_button();
                    cancel_clicked();
                    break;
                case SYNC_BUTTON_TEXT:
                    sync_clicked();
                    action_button.set_label (CANCEL_BUTTON_TEXT);
                    break;
                default:
                    reset_action_button();
                    break;
            }
        });

        var right_box = new Box (Orientation.VERTICAL, 3);
        right_box.pack_end (action_button, false, true, 0);

        var right_box_padding = new Box (Orientation.VERTICAL, 0);
        right_box_padding.pack_start (new Box (Orientation.VERTICAL, 0), true, true, 0);
        right_box_padding.pack_start (right_box, true, true, 0);
        right_box_padding.pack_end (new Box (Orientation.VERTICAL, 0), true, true, 0);

        var wrapper = new Box (Orientation.HORIZONTAL, 0);
        wrapper.pack_start (new Box (Orientation.HORIZONTAL, 0), false, true, DEFAULT_PADDING);
        wrapper.pack_end (new Box (Orientation.HORIZONTAL, 0), false, true, DEFAULT_PADDING);
        wrapper.pack_start (left_box, true, true, 4);
        wrapper.pack_start (new Box (Orientation.HORIZONTAL, 0), false, true, DEFAULT_PADDING);
        wrapper.pack_end (right_box_padding, false, true, DEFAULT_PADDING);

        padding.pack_start (wrapper, true, true, DEFAULT_PADDING);

        widget.add (padding);

        items = new HashMap<int, SpaceWidgetItem>();
        set_size (size);

        /** Adding free-space element **/
        add_item_at_pos ("Free", size, ItemColor.GREY, ItemPosition.END);
    }

    public void reset_action_button () {
        action_button.set_label (SYNC_BUTTON_TEXT);
    }

    public void set_size (double size) {
        double used_space = total_size - free_space_size;
        if (size < used_space) {
            stdout.printf("\nERROR: SpaceWidget: new total size is smaller than used size.\n");
            return;
        }

        total_size = size;
        free_space_size = size;

        update_bar_item_sizes();
    }

    public int add_item (string name, double size, ItemColor color) {
        return add_item_at_pos (name, size, color, ItemPosition.START);
    }

    private int add_item_at_pos (string name, double size, ItemColor color, ItemPosition pos) {
        if (size > free_space_size) {
            stdout.printf("\nERROR: SpaceWidget: Couldn't add item %s. Not enough free space.\n", name);
            return -1; // ERROR
        }

        int index = items.size;

        var item = new SpaceWidgetItem (index, name, size, color);
        items.set(index, item);

        if (pos == ItemPosition.END) {
            bar_wrapper.pack_end (item.bar_item, false, false, 0);
            legend_wrapper.pack_end (item.legend, true, true, 0);
        } else {
            bar_wrapper.pack_start (item.bar_item, false, false, 0);
            legend_wrapper.pack_start (item.legend, true, true, 0);
        }

        update_bar_item_sizes();
        return index;
    }

    public void update_item_size (int index, double size) {
        SpaceWidgetItem? item = items.get(index);

        // Checking if there's enough freespace for the change
        if (item != null && (item.size + free_space_size) >= size) {
            item.set_size(size);
            update_bar_item_sizes();
        }
    }

    private void update_bar_item_sizes () {
        int item_list_size = items.size;
        int actual_width = get_allocated_width ();
        int bar_width = actual_width * 8 / 10;

        if (item_list_size < 1)
            return;

        int total_visible_items = item_list_size;
        int last_visible_id = 0;

        foreach (var item in items) {
            if (item.size <= 0.0)
                total_visible_items --;
            else
                last_visible_id = item.ID;
        }

        if (total_visible_items == 1) {
            if (single_item_visible) {
                full_bar_item.set_size (bar_width);
            } else {
                show_full_bar_item (true, items.get(last_visible_id).color);
                full_bar_item.show();
                full_bar_item.set_size (bar_width);
            }

            return;
        }
        else if (single_item_visible) {
            show_full_bar_item (false, null);
        }

        // Resizing items and calculating free space
        free_space_size = total_size;

        foreach (var item in items) {
            if (item.ID > 0) {
                int width = (int) ((item.size/total_size) * bar_width);
                free_space_size -= item.size;
                item.bar_item.set_size (width);
                item.show ();
            }
        }

        // Resizing free space item:
        var free_space_item = items.get(0);
        free_space_item.set_size (free_space_size);
        int width = (int) ((free_space_item.size/total_size) * bar_width);
        free_space_item.bar_item.set_size (width);
    }

    private void show_full_bar_item (bool show_item, ItemColor? color) {
        if (show_item && color != null) {
            bar_wrapper.hide ();
            bar_wrapper.set_no_show_all (true);
            full_bar_wrapper.set_no_show_all (false);
            full_bar_item = new SpaceWidgetBarFullItem (color, 0);
            full_bar_wrapper.pack_start (full_bar_item, false, false, 0);
            single_item_visible = true;
        } else {
            full_bar_item.destroy ();
            bar_wrapper.set_no_show_all (false);
            full_bar_wrapper.set_no_show_all (true);
            bar_wrapper.show_all ();
            single_item_visible = false;
        }
    }

    public override void size_allocate (Gtk.Allocation allocation) {
        base.size_allocate (allocation);
        update_bar_item_sizes ();
    }
}

private class SpaceWidgetBarItem : Gtk.Button {
    public SpaceWidget.ItemColor color;
    public int hsize = 0;

    private const int BAR_DEFAULT_HEIGHT = 23;

    public SpaceWidgetBarItem (SpaceWidget.ItemColor color, int hsize) {
        this.color = color;
        var style = this.get_style_context ();

        switch (color) {
            case SpaceWidget.ItemColor.BLUE:
                style.add_class ("blue");
                break;
            case SpaceWidget.ItemColor.ORANGE:
                style.add_class ("orange");
                break;
            case SpaceWidget.ItemColor.GREEN:
                style.add_class ("green");
                break;
            case SpaceWidget.ItemColor.RED:
                style.add_class ("red");
                break;
            case SpaceWidget.ItemColor.PURPLE:
                style.add_class ("purple");
                break;
            case SpaceWidget.ItemColor.GREY:
                style.add_class ("grey");
                break;
            default:
                style.add_class ("grey");
                break;
        }

        this.sensitive = false;
        style.add_class ("SpaceBarItem");
        style.add_provider (SpaceWidget.style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);

        this.set_size_request (0, BAR_DEFAULT_HEIGHT);
    }

    public void set_size (int size) {
        if(size == hsize)
            return;

        this.hsize = size;

        this.set_size_request (hsize, BAR_DEFAULT_HEIGHT);

        if (size < 1 && this.visible) {
            this.hide ();
        } else if (!this.visible) {
            this.show ();
        }
    }
}

private class SpaceWidgetBarFullItem : SpaceWidgetBarItem {
    public SpaceWidgetBarFullItem (SpaceWidget.ItemColor color, int hsize) {
        base (color, hsize);
        var style = this.get_style_context ();
        this.sensitive = false;
        style.remove_class("SpaceBarItem");
        style.add_class ("SpaceBarFullItem");
        style.add_provider (SpaceWidget.style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
}

private class LegendItem : Gtk.Button {
    public SpaceWidget.ItemColor color;

    private const int DIAMETER = 20;

    public LegendItem (SpaceWidget.ItemColor color) {
        this.color = color;
        var style = this.get_style_context ();

        switch (color) {
            case SpaceWidget.ItemColor.BLUE:
                style.add_class ("blue");
                break;
            case SpaceWidget.ItemColor.ORANGE:
                style.add_class ("orange");
                break;
            case SpaceWidget.ItemColor.GREEN:
                style.add_class ("green");
                break;
            case SpaceWidget.ItemColor.RED:
                style.add_class ("red");
                break;
            case SpaceWidget.ItemColor.GREY:
                style.add_class ("grey");
                break;
            case SpaceWidget.ItemColor.PURPLE:
                style.add_class ("purple");
                break;
            default:
                style.add_class ("grey");
                break;
        }

        style.add_class ("LegendItem");
        style.add_provider (SpaceWidget.style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
        this.sensitive = false;
        this.set_diameter (DIAMETER);
    }

    public void set_diameter (int diameter) {
        this.set_size_request (diameter, diameter);
    }
}

private class SpaceWidgetItem : GLib.Object {
    public int ID;
    public string name;
    public double size;
    public SpaceWidget.ItemColor color;

    public Gtk.Box legend;
    public SpaceWidgetBarItem bar_item;

    private Gtk.Label title_label;
    private Gtk.Label size_label;

    /** Base Unit: Megabytes (MB) **/
    const double MULT = 1024;
    const double MB = 1;
    const double GB = MULT * MB;
    const double TB = MULT * GB;

    public SpaceWidgetItem (int id, string name, double size, SpaceWidget.ItemColor color) {
        this.name = name;
        this.size = size;
        this.color = color;
        this.ID = id;
        this.legend = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        // set size data
        this.set_size (size);

        var legend_icon = new LegendItem (color);

        var legend_icon_wrapper = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        legend_icon_wrapper.pack_start (new Gtk.Box (Gtk.Orientation.VERTICAL, 0), true, true, 0);
        legend_icon_wrapper.pack_start (legend_icon, false, false, 0);
        legend_icon_wrapper.pack_end (new Gtk.Box (Gtk.Orientation.VERTICAL, 0), true, true, 0);

        if (id > 0)
            legend.pack_end (new Box (Orientation.HORIZONTAL, 0), true, true, 20);

        legend.pack_start (legend_icon_wrapper, true, true, 0);

        title_label = new Gtk.Label ("<span weight='medium' size='10700'>" + name + "</span>");
        title_label.use_markup = true;

        var label_wrapper = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        label_wrapper.pack_start (title_label, true, true, 0);
        label_wrapper.pack_start (size_label, true, true, 0);

        legend.pack_start (label_wrapper, true, true, 7);

        bar_item = new SpaceWidgetBarItem (color, 0);
    }

    public void set_size (double s) {
        size = s;
        var size_text = new StringBuilder();

        if (size <= GB) {
            size_text.append ("%.1f".printf(size/MB));
            size_text.append (" MB");
        } else if (size <= TB) {
            size_text.append ("%.1f".printf(size/GB));
            size_text.append (" GB");
        } else {
            size_text.append ("%.1f".printf(size/TB));
            size_text.append (" TB");
        }

        if (size_label == null)
            size_label = new Label (size_text.str);
        else
            size_label.set_text (size_text.str);
    }

    public void show () {
        if (size > 0.0) {
            show_legend ();
            show_bar_item ();
        } else if (this.ID > 0) {
            hide_legend ();
            hide_bar_item ();
        } else {
            hide_bar_item ();
        }
    }

    /** These functions shouldn't be called directly **/
    public void hide_bar_item () {
        if (bar_item.visible)
            bar_item.hide ();
    }

    public void show_bar_item () {
        if (!bar_item.visible)
            bar_item.show ();
    }

    public void hide_legend () {
        if (legend.visible)
            legend.hide ();
    }

    public void show_legend () {
        if (!legend.visible)
            legend.show_all ();
    }

}
