module logging

import log

const (
	global = &log.Log{level: .info, output_target: .console}
)

interface Any { str() string }

pub fn get_logger() &log.Log {
	return global
}

pub fn fatal(s Any) {
	mut l := get_logger()
	l.fatal(s.str())
}

pub fn error(s Any) {
	mut l := get_logger()
	l.error(s.str())
}

pub fn warn(s Any) {
	mut l := get_logger()
	l.warn(s.str())
}

pub fn info(s Any) {
	mut l := get_logger()
	l.info(s.str())
}

pub fn debug(s Any) {
	mut l := get_logger()
	l.debug(s.str())
}
