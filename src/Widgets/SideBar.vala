/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player and Granite Library
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 * Granite Library:		 http://www.launchpad.net/granite
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
 * 
 * NOTES: The iters returned are child model iters. To work with any function
 * except for add, you need to to use convertToFilter(child iter);
 */

using Gtk;
using Gdk;

namespace ElementaryWidgets {
	
	public class CellRendererExpander : CellRenderer {
		public bool expanded;
		public static int EXPANDER_SIZE = 12;
		
		public CellRendererExpander() {
			expanded = false;
		}
		
		public override void get_size(Widget widget, Rectangle? cell_area, out int x_offset, out int y_offset, out int width, out int height) {
			x_offset = 0;
			y_offset = 4;
			width = 12;
			height = 12;
		}
		
		public override void render(Gdk.Window window, Widget widget, Rectangle background_area, Rectangle cell_area, Rectangle expose_area, CellRendererState flags) {
			Gtk.paint_expander(widget.get_style(), window, StateType.NORMAL, background_area, widget, "treeview", 
								cell_area.x + 12 / 2, cell_area.y + 20 / 2, expanded ? ExpanderStyle.EXPANDED : ExpanderStyle.COLLAPSED);
		}
	}
	
	public enum SideBarColumn {
		COLUMN_OBJECT,
		COLUMN_WIDGET,
		COLUMN_VISIBLE,
		COLUMN_PIXBUF,
		COLUMN_TEXT,
		COLUMN_CLICKABLE
	}
	
	public class SideBar : Gtk.TreeView {
		public TreeStore tree;
		public TreeModelFilter filter;
		
		CellRendererText spacer;
		CellRendererPixbuf pix_cell;
		CellRendererText text_cell;
		CellRendererPixbuf clickable_cell;
		CellRendererExpander expander_cell;
		
		TreeIter? selectedIter;
		
		public bool autoExpanded;
		
		public signal void clickable_clicked(TreeIter iter);
		public signal void true_selection_change(TreeIter selected);
		
		public SideBar() {
			tree = new TreeStore(6, typeof(GLib.Object), typeof(Widget), typeof(bool), typeof(Gdk.Pixbuf), typeof(string), typeof(Gdk.Pixbuf));
			filter = new TreeModelFilter(tree, null);
			set_model(filter);
			
			TreeViewColumn col = new TreeViewColumn();
			col.title = "object";
			this.insert_column(col, 0);
			
			col = new TreeViewColumn();
			col.title = "widget";
			this.insert_column(col, 1);
			
			col = new TreeViewColumn();
			col.title = "visible";
			this.insert_column(col, 2);
			
			col = new TreeViewColumn();
			col.title = "display";
			col.expand = true;
			this.insert_column(col, 3);
			
			// add spacer
			spacer = new CellRendererText();
			col.pack_start(spacer, false);
			col.set_cell_data_func(spacer, spacerDataFunc);
			spacer.xpad = 8;
			
			// add pixbuf
			pix_cell = new CellRendererPixbuf();
			col.pack_start(pix_cell, false);
			col.set_cell_data_func(pix_cell, pixCellDataFunc);
			col.set_attributes(pix_cell, "pixbuf", SideBarColumn.COLUMN_PIXBUF);
			
			// add text
			text_cell = new CellRendererText();
			col.pack_start(text_cell, true);
			col.set_cell_data_func(text_cell, textCellDataFunc);
			col.set_attributes(text_cell, "markup", SideBarColumn.COLUMN_TEXT);
			text_cell.ellipsize = Pango.EllipsizeMode.END;
			text_cell.xalign = 0.0f;
			text_cell.xpad = 0;
			
			// add clickable icon
			clickable_cell = new CellRendererPixbuf();
			col.pack_start(clickable_cell, false);
			col.set_cell_data_func(clickable_cell, clickableCellDataFunc);
			col.set_attributes(clickable_cell, "pixbuf", SideBarColumn.COLUMN_CLICKABLE);
			clickable_cell.mode = CellRendererMode.ACTIVATABLE;
			clickable_cell.xpad = 2;
			clickable_cell.xalign = 1.0f;
			clickable_cell.stock_size = 16;
			
			// add expander
			expander_cell = new CellRendererExpander();
			col.pack_start(expander_cell, false);
			col.set_cell_data_func(expander_cell, expanderCellDataFunc);
			
			this.set_headers_visible(false);
			//this.set_expander_column(get_column(3));
			this.set_show_expanders(false);
			filter.set_visible_column(SideBarColumn.COLUMN_VISIBLE);
			this.set_grid_lines(TreeViewGridLines.NONE);
			this.name = "SidebarContent";
			
			
			this.get_selection().changed.connect(selectionChange);
			this.button_press_event.connect(sideBarClick);
		}
		
		public void spacerDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
			TreePath path = model.get_path(iter);
			int depth = path.get_depth();
			
			renderer.visible = (depth > 1);
			renderer.xpad = (depth > 1) ? 8 : 0;
		}
		
		public void pixCellDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
			TreePath path = model.get_path(iter);
			
			if(path.get_depth() == 1) {
				renderer.visible = false;
			}
			else {
				renderer.visible = true;
			}
		}
		
		public void textCellDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
			TreePath path = model.get_path(iter);
			int depth = path.get_depth();
			string text = "";
			model.get(iter, SideBarColumn.COLUMN_TEXT, out text);
			
			if(depth == 1) {
				((CellRendererText)renderer).markup = "<b>" + text + "</b>";
			}
			else {
				((CellRendererText)renderer).markup = text;
			}
		}
		
		public void clickableCellDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
			Gdk.Pixbuf clickable;
			model.get(iter, SideBarColumn.COLUMN_CLICKABLE, out clickable);
			
			if(clickable != null) {
				renderer.visible = true;
			}
			else {
				renderer.visible = false;
			}
		}
		
		public void expanderCellDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
			TreePath path = model.get_path(iter);
			
			renderer.visible = (path.get_depth() == 1);
			((CellRendererExpander)renderer).expanded = is_row_expanded(path);
		}
		
		/* Convenient add/remove/edit methods */
		public TreeIter addItem(TreeIter? parent, GLib.Object? o, Widget? w, Gdk.Pixbuf? pixbuf, string text, Gdk.Pixbuf? clickable) {
			TreeIter iter;
			stdout.printf("added %s\n", text);
			tree.append(out iter, parent);
			tree.set(iter, 0, o, 1, w, 2, true, 3, pixbuf, 4, text, 5, clickable);
			
			if(parent != null) {
				tree.set(parent, 2, true);
			}
			else {
				tree.set(iter, 2, false);
			}
			
			expand_all();
			return iter;
		}
		
		public bool removeItem(TreeIter iter_f) {
			TreeIter iter = convertToChild(iter_f);
			
			TreeIter parent;
			if(tree.iter_parent(out parent, iter)) {
				if(tree.iter_n_children(parent) > 1)
					tree.set(parent, 2, true);
				else
					tree.set(parent, 2, false);
			}
			
			return tree.remove(iter);
		}
		
		public TreeIter? getSelectedIter() {
			TreeModel mod;
			TreeIter sel;
			
			if(this.get_selection().get_selected(out mod, out sel)) {
				return sel;
			}
			
			return null;
		}
		
		public bool expandItem(TreeIter iter, bool expanded) {
			TreePath path = filter.get_path(iter);
			
			if(path.get_depth() != 1)
				return false;
			
			return this.expand_row(path, false);
		}
		
		public GLib.Object? getObject(TreeIter iter) {
			GLib.Object o;
			filter.get(iter, SideBarColumn.COLUMN_OBJECT, out o);
			return o;
		}
		
		public Widget? getWidget(TreeIter iter) {
			Widget w;
			filter.get(iter, SideBarColumn.COLUMN_WIDGET, out w);
			return w;
		}
		
		public Widget? getSelectedWidget() {
			Widget w;
			filter.get(selectedIter, SideBarColumn.COLUMN_WIDGET, out w);
			return w;
		}
		
		/* stops user from selecting the root nodes */
		public void selectionChange() {
			TreeModel model;
			TreeIter pending;
			
			if(!this.get_selection().get_selected(out model, out pending)) { // user has nothing selected, reselect last selected
				if(selectedIter != null)
					this.get_selection().select_iter(selectedIter);
				
				return;
			}
			
			TreePath path = model.get_path(pending);
			
			if(path.get_depth() == 1) {
				this.get_selection().unselect_all();
				
				if(selectedIter != null)
					this.get_selection().select_iter(selectedIter);
			}
			else {
				selectedIter = pending;
				true_selection_change(selectedIter);
			}
		}
		
		/* click event functions */
		private bool sideBarClick(Gdk.EventButton event) {
			if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
				// select one based on mouse position
				TreeIter iter;
				TreePath path;
				TreeViewColumn column;
				int cell_x;
				int cell_y;
				
				this.get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);
				
				if(!filter.get_iter(out iter, path))
					return false;
				
				if(overClickable(iter, column, (int)cell_x, (int)cell_y)) {
					clickable_clicked(iter);
				}
				else if(overExpander(iter, column, (int)cell_x, (int)cell_y)) {
					if(is_row_expanded(path))
						this.collapse_row(path);
					else
						this.expand_row(path, true);
				}
			}
			
			return false;
		}
		
		private bool overClickable(TreeIter iter, TreeViewColumn col, int x, int y) {
			Pixbuf pix;
			filter.get(iter, 5, out pix);
			
			if(pix == null)
				return false;
			
			int cell_x;
			int cell_width;
			col.cell_get_position(clickable_cell, out cell_x, out cell_width);
			
			if(x > cell_x && x < cell_x + cell_width)
				return true;
			
			return false;
		}
		
		private bool overExpander(TreeIter iter, TreeViewColumn col, int x, int y) {
			if(filter.get_path(iter).get_depth() != 1)
				return false;
			
			/* for some reason, the pixbuf SOMETIMES takes space, somtimes doesn't so cope for that */
			int pixbuf_start;
			int pixbuf_width;
			col.cell_get_position(pix_cell, out pixbuf_start, out pixbuf_width);
			
			int cell_start;
			int cell_width;
			col.cell_get_position(expander_cell, out cell_start, out cell_width);
			
			cell_start -= pixbuf_start;
			
			if(x > cell_start)
				return true;
			
			return false;
		}
		
		/* Helpers for child->filter, filter->child */
		public TreeIter? convertToFilter(TreeIter? child) {
			if(child == null)
				return null;
			
			TreeIter rv;
			filter.convert_child_iter_to_iter(out rv, child);
			
			return rv;
		}
		
		public TreeIter? convertToChild(TreeIter? filt) {
			if(filt == null)
				return null;
			
			TreeIter rv;
			filter.convert_iter_to_child_iter(out rv, filt);
			
			return rv;
		}
		
	}
	
}