using Gtk;
using Gdk;
using Gee;

public class BeatBox.SimpleOptionChooser : EventBox {
	Menu menu;
	LinkedList<CheckMenuItem> items;
	Pixbuf enabled;
	Pixbuf disabled;
	
	int clicked_index;
	int previous_index; // for left click
	bool toggling;
	
	public signal void option_changed(int index);
	
	public SimpleOptionChooser(Pixbuf enabled, Pixbuf disabled) {
		this.enabled = enabled;
		this.disabled = disabled;
		menu = new Menu();
		items = new LinkedList<CheckMenuItem>();
		toggling = false;
		
		width_request  = (enabled.width > disabled.width) ? enabled.width : disabled.width;
		height_request = (enabled.height > disabled.height) ? enabled.height : disabled.height;
		
		clicked_index = 0;
		previous_index = 1;
		
		// make the background white
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		modify_bg(StateType.NORMAL, c);
		
		button_press_event.connect(buttonPress);
		expose_event.connect(exposeEvent);
	}
	
	public void setOption(int index) {
		if(index >= items.size)
			return;
		
		for(int i = 0;i < items.size; ++i) {
			if(i == index)
				items.get(i).set_active(true);
			else
				items.get(i).set_active(false);
		}
		
		clicked_index = index;
		option_changed(index);
		
		queue_draw();
	}
	
	public int appendItem(string text) {
		var item = new CheckMenuItem.with_label(text);
		items.add(item);
		menu.append(item);
		
		item.toggled.connect( () => {
			if(!toggling) {
				toggling = true;
				
				if(clicked_index != items.index_of(item))
					setOption(items.index_of(item));
				else
					setOption(0);
				
				/*clicked_index = items.index_of(item);
				option_changed(clicked_index);
				
				foreach(CheckMenuItem cmi in items) {
					if(cmi != item)
						cmi.set_active(false);
				}
				*/
				toggling = false;
			}
		});
		
		item.show();
		
		return items.size - 1;
	}
	
	public virtual bool buttonPress(Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			if(clicked_index == 0)
				setOption(previous_index);
			else {
				previous_index = clicked_index;
				setOption(0);
			}
		}
		else if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
			menu.popup (null, null, null, 3, get_current_event_time());
		}
		
		return false;
	}
	
	public virtual bool exposeEvent(EventExpose event) {
		event.window.draw_pixbuf(
				style.bg_gc[0], (clicked_index != 0) ? enabled : disabled,
				0, 0, (event.area.width - width_request)/2, 0, width_request, height_request,
				Gdk.RgbDither.NONE, 0, 0
			);
			
		return true;
	}
}