class_name MusicJob
extends RefCounted
## Renders one `MusicTrack` into clips on a worker thread (`WorkerThreadPool`), so building the
## music never stalls a frame. A looping track gives one looping clip per layer; a stinger gives
## one clip with every layer mixed in.

var track: MusicTrack
var task_id: int = -1
## Filled by `run` (on the worker thread); read only once the task is done.
var clips: Array[AudioStreamWAV] = []


func _init(what: MusicTrack) -> void:
	track = what


func start() -> void:
	task_id = WorkerThreadPool.add_task(run, false, "music %s" % track.id)


## True once the clips are ready (and the task has been waited for).
func collect() -> bool:
	if task_id < 0 or not WorkerThreadPool.is_task_completed(task_id):
		return false
	WorkerThreadPool.wait_for_task_completion(task_id)
	task_id = -1
	return true


func run() -> void:
	var stems: Array[PackedFloat32Array] = MusicRender.render_track(track)
	var made: Array[AudioStreamWAV] = []
	if track.loops:
		for stem: PackedFloat32Array in stems:
			made.append(MusicRender.to_wav(stem, true))
	else:
		made.append(MusicRender.to_wav(MusicRender.mix(stems), false))
	clips = made
