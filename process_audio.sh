# Directory containing the input audio files
input_dir="snippets_raw"
output_dir="snippets_processed"

# Normalize audio to target_loud if the integrated loudness is outside the range [min_loud, max_loud]
target_loud=-14
max_loud=-10
min_loud=-18

measure_loudness() {
    integrated_loudness=$(ffmpeg -i "$1" -af ebur128 -f null - 2>&1 | awk '/I:/ {print $2}' | tail -n 1)
    echo "$integrated_loudness"
}

# Loop through the files in the input directory
for file in "$input_dir"/*.mp3; do
    if [ -f "$file" ]; then
        # Get the filename without extension
        filename=$(basename "$file")
        filename_no_ext="${filename%.*}"

        temp_file="$output_dir/${filename_no_ext}_temp.mp3"
        output_file="$output_dir/${filename_no_ext}_norm.mp3"

        # Silence filtering
        ffmpeg -i "$file" -af silenceremove=start_periods=1:start_duration=0:start_threshold=-50dB:stop_periods=1:stop_duration=0:stop_threshold=-50dB "$temp_file"

        loud=measure_loudness "$temp_file"

        if (( $(echo "$loud > $max_loud" | bc -l) )); then
            ffmpeg -i "$temp_file" -af loudnorm=I="$target_loud":LRA=11:TP=-1.5 "$output_file"
            rm "$temp_file"
        elif (( $(echo "$loud < $min_loud" | bc -l) )); then
            ffmpeg -i "$temp_file" -af loudnorm=I="$target_loud":LRA=11:TP=-1.5 "$output_file"
            rm "$temp_file"
        else
            mv "$temp_file" "$output_file"
        fi
    fi
done

echo "Normalization complete."

