package voicesplitting.voice;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import voicesplitting.utils.MathUtils;
import voicesplitting.utils.MidiNote;
import voicesplitting.voice.hmm.HmmVoiceSplittingModelParameters;

/**
 * A <code>Voice</code> is a node in the LinkedList representing a voice.
 * <p>
 * Each Voice object has only a {@link #previous} pointer and a {@link #mostRecentNote}.
 * Only a previous pointer is needed because we allow for Voices to split and clone themselves,
 * keeping the beginning of their note sequences identical. This allows us to have multiple
 * LinkedLists of notes without needing multiple full List objects. Rather, they all point
 * back to their common prefix LinkedLists.
 * 
 * @author Andrew McLeod - 6 April, 2015
 * @version 1.0
 * @since 1.0
 */
public class Voice implements Comparable<Voice> {
	/**
	 * The Voice preceding this one.
	 */
	private final Voice previous;
	
	/**
	 * The most recent {@link MidiNote} of this voice.
	 */
	private final MidiNote mostRecentNote;
	
	/**
	 * Create a new Voice with the given previous Voice and note.
	 * 
	 * @param note {@link #mostRecentNote}
	 * @param prev {@link #previous}
	 */
	public Voice(MidiNote note, Voice prev) {
		previous = prev;
		mostRecentNote = note;
	}
	
	/**
	 * Create a new Voice with no preceding Voice (it will be null).
	 * 
	 * @param note {@link #mostRecentNote}
	 */
	public Voice(MidiNote note) {
		this(note, null);
	}
	
	/**
	 * Get the probability that the given note belongs to this Voice.
	 * 
	 * @param note The note we want to add.
	 * @param params The parameters to use.
	 * @return The probability that the given note belongs to this Voice.
	 */
	public double getProbability(MidiNote note, HmmVoiceSplittingModelParameters params) {
		double pitch = pitchScore(getWeightedLastPitch(params), note.getPitch(), params);
		double gap = gapScore(note.getOnsetTime(), mostRecentNote.getOffsetTime(), params);
		return pitch * gap;
	}

	/**
	 * Get the pitch closeness of the two given pitches. This value should be higher
	 * the closer together the two pitch values are. The first input parameter is a double
	 * because it is drawn from {@link #getWeightedLastPitch(HmmVoiceSplittingModelParameters)}.
	 * 
	 * @param weightedPitch A weighted pitch, drawn from {@link #getWeightedLastPitch(HmmVoiceSplittingModelParameters)}.
	 * @param pitch An exact pitch.
	 * @param params The parameters to use.
	 * @return The pitch score of the given two pitches, a value between 0 and 1.
	 */
	private double pitchScore(double weightedPitch, int pitch, HmmVoiceSplittingModelParameters params) {
		return MathUtils.gaussianWindow(weightedPitch, pitch, params.PITCH_STD);
	}

	/**
	 * Get the temporal closeness of the two given times. This value should be higher
	 * the closer together the two time values are.
	 * 
	 * @param time1 A time.
	 * @param time2 Another time.
	 * @param params The parameters to use.
	 * @return The gap score of the two given time values, a value between 0 and 1.
	 */
	private double gapScore(long time1, long time2, HmmVoiceSplittingModelParameters params) {
		double timeDiff = Math.abs(time2 - time1);
		double inside = Math.max(0, -timeDiff / params.GAP_STD_MICROS + 1);
		double log = Math.log(inside) + 1;
		return Math.max(log, params.MIN_GAP_SCORE);
	}
	
	/**
	 * Decide if we can add a note with the given length at the given time based on the given parameters.
	 * 
	 * @param time The onset time of the note we want to add.
	 * @param length The length of the note we want to add.
	 * @param params The parameters to use.
	 * @return True if we can add a note of the given duration at the given time. False otherwise.
	 */
	public boolean canAddNoteAtTime(long time, long length, HmmVoiceSplittingModelParameters params) {
		long overlap = mostRecentNote.getOffsetTime() - time;
		
		return overlap <= mostRecentNote.getDurationTime() / 2 && overlap < length;
	}

	/**
	 * Get the weighted pitch of this voice. That is, the weighted mean of the pitches of the last
	 * {@link HmmVoiceSplittingModelParameters#PITCH_HISTORY_LENGTH} notes contained in this Voice
	 * (or all of the notes, if there are fewer than that in total), where each successive note's pitch
	 * is weighted twice as much as each preceding note's.
	 * 
	 * @param params The paramters to use.
	 * @return The weighted pitch of this voice.
	 */
	public double getWeightedLastPitch(HmmVoiceSplittingModelParameters params) {
		double weight = 1;
		double totalWeight = 0;
		double sum = 0;
		
		// Most recent PITCH_HISTORY_LENGTH notes
		Voice noteNode = this;
		for (int i = 0; i < params.PITCH_HISTORY_LENGTH && noteNode != null; i++, noteNode = noteNode.previous) {
			sum += noteNode.mostRecentNote.getPitch() * weight;
			
			totalWeight += weight;
			weight *= 0.5;
		}
		
		return sum / totalWeight;
	}

	/**
	 * Get the number of notes we've correctly grouped into this voice, based on the most common voice in the voice.
	 * 
	 * @return The number of notes we've assigned into this voice correctly.
	 */
	public int getNumNotesCorrect() {
		Map<Integer, Integer> counts = new HashMap<Integer, Integer>();
		
		for (Voice noteNode = this; noteNode != null; noteNode = noteNode.previous) {
			int channel = noteNode.mostRecentNote.getCorrectVoice();
			if (!counts.containsKey(channel)) {
				counts.put(channel, 0);
			}
				
			counts.put(channel, counts.get(channel) + 1);
		}
				
		int maxCount = -1;
		for (int count : counts.values()) {
			maxCount = Math.max(maxCount, count);
		}
		
		return maxCount;
	}
	
	/**
	 * Get the number of links in this Voice which are correct. That is, the number of times
	 * that two consecutive notes belong to the same gold standard voice and should indeed be
	 * consecutive in that voice.
	 * 
	 * @param goldStandard The gold standard voices for this song.
	 * @return The number of times that two consecutive notes belong to the same midi channel.
	 */
	public int getNumLinksCorrect(List<List<MidiNote>> goldStandard) {
		int count = 0;
		int index = -1;
		
		for (Voice node = this; node.previous != null; node = node.previous) {
			MidiNote guessedPrev = node.previous.mostRecentNote;
			MidiNote note = node.mostRecentNote;
			
			if (note.getCorrectVoice() == guessedPrev.getCorrectVoice()) {
				int channel = note.getCorrectVoice();
				if (index == -1) {
					// No valid index - refind
					index = goldStandard.get(channel).indexOf(note);
				}
				
				if (index != 0 && goldStandard.get(channel).get(--index).equals(guessedPrev)) {
					// Match!
					count++;
					
				} else {
					// No match - invalidate index
					index = -1;
				}
			} else {
				// Different track - invalidate index
				index = -1;
			}
		}
		
		return count;
	}
	
	/**
	 * Get the number of notes in the linked list with this node as its tail.
	 * 
	 * @return The number of notes.
	 */
	public int getNumNotes() {
		if (previous == null) {
			return 1;
		}
		
		return 1 + previous.getNumNotes();
	}

	/**
	 * Get the List of notes which this node is the tail of, in chronological order.
	 * 
	 * @return A List of notes in chronological order, ending with this one.
	 */
	public List<MidiNote> getNotes() {
		List<MidiNote> list = previous == null ? new ArrayList<MidiNote>() : previous.getNotes();
		
		list.add(mostRecentNote);
		
		return list;
	}
	
	/**
	 * Get the most recent note in this voice.
	 * 
	 * @return {@link #mostRecentNote}
	 */
	public MidiNote getMostRecentNote() {
		return mostRecentNote;
	}
	
	/**
	 * Get the voice ending at the previous note in this voice.
	 * 
	 * @return {@link #previous}
	 */
	public Voice getPrevious() {
		return previous;
	}
	
	/**
	 * Get the String representation of this object, which is simply the List of {@link MidiNote}s returned by
	 * {@link #getNotes()}.
	 * 
	 * @return The String representation of this object.
	 */
	@Override
	public String toString() {
		return getNotes().toString();
	}

	/**
	 * Compare the given Voice to this one and return their difference. Voices are ordered
	 * first by their {@link #mostRecentNote}, followed by their {@link #previous} pointer.
	 * 
	 * @param o The Voice we are comparing to.
	 * @return A positive number if this Voice should come first, negative if the given one
	 * should come first, or 0 if they are equal.
	 */
	@Override
	public int compareTo(Voice o) {
		if (o == null) {
			return -1;
		}
		
		int result = mostRecentNote.compareTo(o.mostRecentNote);
		if (result != 0) {
			return result;
		}
		
		if (previous == o.previous) {
			return 0;
		}
		
		if (previous == null) {
			return 1;
		}
		
		return previous.compareTo(o.previous);
	}
}
