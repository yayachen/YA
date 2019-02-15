package voicesplitting.gui;

import java.awt.Color;

/**
 * The <code>GUIConstants</code> class holds constant values to be used for the GUI
 * layout.
 * <p>
 * There is no need for an object of this class to ever be instantiated.
 * 
 * @author Andrew McLeod - 18 June, 2015
 * @version 1.0
 * @since 1.0
 */
public class GUIConstants {

	/**
	 * The width of the left border, and the height of the top border, where the scales are.
	 */
	public static final int SCALE_SIZE = 30;
	
	/**
	 * The width and height of the zoom buttons.
	 */
	public static final int ZOOM_BUTTON_SIZE = 15;
	
	/**
	 * The minimum vertical scale value.
	 */
	public static final int VERTICAL_SCALE_MIN = 6;
	
	/**
	 * The minimum vertical scale zoom level.
	 */
	public static final int HORIZONTAL_SCALE_MIN = 250;
	
	/**
	 * String for the separate voices button.
	 */
	public static final String SEPARATE = "Separate Voices";
	
	/**
	 * String for the unseparate voices button.
	 */
	public static final String UNSEPARATE = "Undo Voice Separation";
	
	/**
	 * The Colors to use for coloring {@link MidiNoteGUI}s based on voice.
	 */
	public static final Color[] COLORS = new Color[] {
			Color.decode("#00FF00"),
			Color.decode("#0000FF"),
			Color.decode("#FF0000"),
			Color.decode("#01FFFE"),
			Color.decode("#FFA6FE"),
			Color.decode("#FFDB66"),
			Color.decode("#006401"),
			Color.decode("#010067"),
			Color.decode("#95003A"),
			Color.decode("#007DB5"),
			Color.decode("#FF00F6"),
			Color.decode("#FFEEE8"),
			Color.decode("#774D00"),
			Color.decode("#90FB92"),
			Color.decode("#0076FF"),
			Color.decode("#D5FF00")
	};
}
