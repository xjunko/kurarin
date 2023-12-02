module logging

import log

pub const global = &KurarinLogger{
	Log: &log.Log{
		level: .info
		output_target: .console
	}
}

pub struct KurarinLogger {
	log.Log
pub mut:
	logs []string
}

interface Any {
	str() string
}

pub fn get_logger() &KurarinLogger {
	return logging.global
}

pub fn fatal(s Any) {
	mut l := get_logger()
	l.fatal(s.str())
	l.logs << '[${@METHOD}]: ${s.str()}'
}

pub fn error(s Any) {
	mut l := get_logger()
	l.error(s.str())
	l.logs << '[${@METHOD}]: ${s.str()}'
}

pub fn warn(s Any) {
	mut l := get_logger()
	l.warn(s.str())
	l.logs << '[${@METHOD}]: ${s.str()}'
}

pub fn info(s Any) {
	mut l := get_logger()
	l.info(s.str())
	l.logs << '[${@METHOD}]: ${s.str()}'
}

pub fn debug(s Any) {
	mut l := get_logger()
	l.debug(s.str())
	l.logs << '[${@METHOD}]: ${s.str()}'
}
