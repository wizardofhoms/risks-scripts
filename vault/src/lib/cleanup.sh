
# This file contains:
# - Functions needed to register variables to be cleaned. 
# - Code to be triggered on exit/returns to perform security cleanup
# - Any variable in which code will store some stuff to be treated.

declare -a CLEANUP_VARS

# _defer_cleanup takes an arbitrary amount of variables 
# that will be cleaned up further down the workflow
_defer_cleanup ()
{
    _verbose "Variables registered for cleanup: ( ${*} )"
    CLEANUP_VARS+=("$@")
}

# Cleanup anything sensitive before exiting.
# Originally copied from tomb code.
_endgame() {

	# option_value_contains -o ro || {
	# 	# Restore access time of sensitive files
	# 	[[ -z $TOMBFILESSTAT ]] || _restore_stat
	# }

	# Prepare some random material to overwrite vars
	local rr="$RANDOM"
	while [[ ${#rr} -lt 500 ]]; do
		rr+="$RANDOM"
	done

	# Ensure no information is left in unallocated memory
	IDENTITY="$rr";		        unset IDENTITY 
	EMAIL="$rr";		        unset EMAIL 
	MASTER_PASS="$rr";          unset MASTER_PASS 
	FILE_ENCRYPTION_KEY="$rr";  unset FILE_ENCRYPTION_KEY 
	GPG_PASS="$rr";		        unset GPG_PASS 
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

