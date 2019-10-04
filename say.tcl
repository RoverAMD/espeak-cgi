#!/opt/ActiveTcl-8.6/bin/tclsh
package require base64

proc since {listing {index 1}} {
	set idx 0
	set result {}
	foreach el $listing {
		if {$idx >= $index} {
			lappend result $el
		}
		incr idx
	}
	return $result
}

proc cgiParams {str} {
	set result [dict create]
	set splitStr [split $str {&}]
	foreach el $splitStr {
		set tok [split $el {=}]
		dict set result [lindex $tok 0] [join [since $tok] {=}]
	}
	return $result
}


proc plainError {text} {
	puts "Content-type: text/plain"
	puts "Status: 500 Internal Server Error"
	puts ""
	puts "$text"
	exit 1
}

set executable "espeak-ng"
if {[catch {exec -ignorestderr -- command -v espeak-ng}]} {
	plainError "espeak-ng is absent, please install it on this server"
}

set pitch 76
set wpm 175
set voice en-us
set tosay "Everything works, but nothing was specified"
set allParams [cgiParams $::env(QUERY_STRING)]

dict for {key val} $allParams {
	if {$key == "voice"} {
		set voice $val
	} elseif {$key == "pitch"} {
		set pitch $val
	} elseif {$key == "wpm"} {
		set wpm $val
	} elseif {$key == "text"} {
		set tosay [base64::decode [string map {- + - /} $val]]
	} elseif {$key == "textp"} {
		set tosay $val
	}
}

if {[catch {exec -ignorestderr -- $executable -w /tmp/speech.wav -p $pitch -s $wpm -v $voice $tosay}]} {
	plainError "espeak crashed"
}

puts "Content-type: audio/wav"
puts ""
chan configure stdout -translation binary -buffering none -encoding binary
set fp [open /tmp/speech.wav r]
fconfigure $fp -translation binary -encoding binary
puts -nonewline [read $fp]
close $fp
file delete -force /tmp/speech.wav
exit 0
