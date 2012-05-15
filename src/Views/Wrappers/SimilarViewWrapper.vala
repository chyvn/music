// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class BeatBox.SimilarViewWrapper : ViewWrapper {

    public bool have_media { get { return media_count >= REQUIRED_MEDIA; } }

    private const int REQUIRED_MEDIA = 10;
    private bool fetched;

    private Media base_media;

    public SimilarViewWrapper (LibraryWindow lw, TreeViewSetup tvs) {

        base (lw, tvs, -1);

        // Add list view
        list_view = new ListView (this, tvs);

        // Add alert
        embedded_alert = new Granite.Widgets.EmbeddedAlert();

		// Refresh view layout
		pack_views ();

        fetched = false;

        // Connect data signals
        lm.media_played.connect (on_media_played);
        lm.lfm.similar_retrieved.connect (similar_retrieved);
    }

    void on_media_played (Media new_media) {
        fetched = false;

        // Avoid fetching if the user is playing the queried results
        // '!is_current_wrapper' would work too ;)
        if (!list_view.get_is_current_list()) {
            base_media = new_media;

            if (base_media != null) {
                // Say we're fetching media
                embedded_alert.set_alert (_("Fetching similar songs..."), _("Finding songs similar to %s by %s").printf ("<b>" + String.escape (base_media.title) + "</b>", "<b>" + String.escape (base_media.artist) + "</b>"), null, false);
            }
            else {
                // Base media is null, so show the proper warning. As this happens often, tell
                // the users more about this view instead of scaring them away
                embedded_alert.set_alert (_("Similar Song View"), _("In this view, %s will automatically find songs similar to the one you're playing. You can then start playing those songs, or save them as a playlist for later.").printf (String.escape (lw.app.get_name ())), null, true, Granite.AlertLevel.INFO);
            }

            // Show the alert box
            set_active_view (ViewType.ALERT);
        }
    }

    void similar_retrieved (Gee.LinkedList<int> similar_internal, Gee.LinkedList<Media> similar_external) {
        fetched = true;
        set_media (similar_internal);
    }

    public void save_playlist () {
        if (base_media == null) {
            warning ("User tried to save similar playlist, but there is no base media\n");
            return;
        }

        var p = new Playlist();
        p.name = _("Similar to %s").printf (base_media.title);

        var to_add = new Gee.LinkedList<Media>();

        foreach (Media m in list_view.get_media ()) {
            to_add.add (m);
        }

        p.add_media (to_add);

        lm.add_playlist (p);
        lw.addSideListItem (p);
    }


    protected override bool check_have_media () {
        if (!list_view.get_is_current_list()) {

            /**
             * We don't want to populate with songs if there are not enough for it to be valid.
             * Only populate with at least REQUIRED_MEDIA songs.
             */
            if (media_count >= REQUIRED_MEDIA) {
                select_proper_content_view ();
                return true;
            }

            /* There is no media and no alert box to tell the world about it */
            if (!has_embedded_alert) {
                select_proper_content_view ();
                return false;
            }

            /* At this point, there's no media (we couldn't find enough) and there's obviously
             * an embedded alert widget available.
             */            
            if (base_media != null) {
                // say we could not find similar media
                embedded_alert.set_alert (_("No similar songs found"), _("%s could not find songs similar to %s by %s. Make sure all song info is correct and you are connected to the Internet. Some songs may not have matches.").printf (String.escape (lw.app.get_name ()), "<b>" + String.escape (base_media.title) + "</b>", "<b>" + String.escape (base_media.artist) + "</b>"), null, true, Granite.AlertLevel.INFO);
                            
            }

            // Show the alert box
            set_active_view (ViewType.ALERT);
        }

        return false;
    }
}
