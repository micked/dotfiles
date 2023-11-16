# SLURM functions
sout() {
    # Check if a job ID is provided as an argument
    if [ $# -ne 1 ]; then
        >&2 echo "Get stdout of Slurm Job"
        >&2 echo "Usage: sout <job_id>"
        return 1
    fi
    # Get job information using scontrol
    job_info=$(scontrol show job "$1")
    # Extract the StdOut filepath from the job information
    stdout_filepath=$(echo "$job_info" | grep -o 'StdOut=[^ ]*' | cut -d= -f2)
    # Check if the StdOut file exists
    if [ -e "$stdout_filepath" ]; then
        # Display the content of the StdOut file
        echo "$stdout_filepath"
    else
        >&2 echo "StdOut file not found: $stdout_filepath"
    fi
}

serr() {
    # Check if a job ID is provided as an argument
    if [ $# -ne 1 ]; then
        >&2 echo "Get stderr of Slurm Job"
        >&2 echo "Usage: serr <job_id>"
        return 1
    fi
    # Get job information using scontrol
    job_info=$(scontrol show job "$1")
    # Extract the StdErr filepath from the job information
    stderr_filepath=$(echo "$job_info" | grep -o 'StdErr=[^ ]*' | cut -d= -f2)
    # Check if the StdErr file exists
    if [ -e "$stderr_filepath" ]; then
        # Display the content of the StdErr file
        echo "$stderr_filepath"
    else
        >&2 echo "StdErr file not found: $stderr_filepath"
    fi
}
