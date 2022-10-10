
# Cleanup anything sensitive before exiting.
# Originally copied from tomb code.
_endgame() {

	# Prepare some random material to overwrite vars
	local rr="$RANDOM"
	while [[ ${#rr} -lt 500 ]]; do
		rr+="$RANDOM"
	done

	# Ensure no information is left in unallocated memory
	IDENTITY="$rr";		        unset IDENTITY 
	FILE_ENCRYPTION_KEY="$rr";  unset FILE_ENCRYPTION_KEY 
	GPG_PASS="$rr";		        unset GPG_PASS 

    echo "test" > ~/endgame
}

# Trap functions for the _endgame event
TRAPINT()  { _endgame INT;	}
TRAPEXIT() { _endgame EXIT;	}
TRAPHUP()  { _endgame HUP;	}
TRAPQUIT() { _endgame QUIT;	}
TRAPABRT() { _endgame ABORT; }
TRAPKILL() { _endgame KILL;	}
TRAPPIPE() { _endgame PIPE;	}
TRAPTERM() { _endgame TERM;	}
TRAPSTOP() { _endgame STOP;	}

