make_lateral_view;redraw
save_tiff "Lateral.tiff"

rotate_brain_y 180;redraw
save_tiff "Medial.tiff"

make_lateral_view;redraw
rotate_brain_y 90;redraw
save_tiff "Posterior.tiff"

rotate_brain_y -180;redraw
save_tiff "Anterior.tiff"

make_lateral_view;redraw
rotate_brain_x -90;redraw
save_tiff "Superior.tiff"

rotate_brain_x -180;redraw
save_tiff "Inferior.tiff"
