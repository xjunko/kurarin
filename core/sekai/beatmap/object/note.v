module object

pub struct NoteObject {
	BaseNoteObject

	pub mut:
		tick f64
		lane f64
		width f64
		typ int
}