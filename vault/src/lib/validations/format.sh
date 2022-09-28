
# Checks that a partition size given in absolute terms has a valid unit
validate_partition_size () {
    case "$1" in *K|*M|*G|*T|*P) return ;; esac
    echo "Absolute size must comprise a valid unit (K/M/G/T/P, eg. 100M)"
}
