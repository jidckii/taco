#!/bin/bash

queue_path=/home/transcoder/taco/frank_taco/Lets_video/
source_path=/home/transcoder/taco/source/
trans_path=/home/transcoder/taco/trans/
end_path=/home/transcoder/taco/frank_taco/Take_h264/
log_dir=/home/transcoder/taco/logs/

ps_wait(){
  sleep 1
  ps_status=`ps -e | grep ffmpeg | wc -l`
  while [ "$ps_status" -gt "0" ]; do
    sleep 10
    ps_status=`ps -e | grep ffmpeg | wc -l`
  done
}

while true; do
  tmp_video_size1=`du -s $queue_path | awk '{print $1}'`
  sleep 10

  while [ "$tmp_video_size1" -gt "1000" ]; do   # Проверям размер раталога
    tmp_video_size1=`du -s $queue_path | awk '{print $1}'`
    sleep 60
    tmp_video_size2=`du -s $queue_path | awk '{print $1}'`

    if [ "$tmp_video_size1" -ne "$tmp_video_size2" ]; then  # Убеждаемся, что временный каталог более не растет
      continue
    fi

    next_file=`ls -t -r -1 $queue_path | awk '{print $1}' | head -n 1`
    cp $queue_path$next_file $source_path
    sleep 1
    rm $queue_path$next_file
    end_file=`ls -1 $source_path`

    ps_wait

    ffmpeg \
          -i $source_path$end_file -map 0 -c:v libx264 -preset veryfast -g 25 -keyint_min 4\
          -c:a aac -f mp4 $trans_path$end_file.mp4 > $log_dir$end_file.log 2>&1 & pid=$!

    wait $pid

    tar -c -f $log_dir$end_file.tar $log_dir$end_file.log > /dev/null 2>&1
    cp -R $trans_path$end_file.mp4 $end_path
    cp -R $log_dir$end_file.tar $end_path
    sleep 1
    rm -r -f $source_path* && rm -r -f $trans_path* && rm -r -f $log_dir* > /dev/null 2>&1
  done
done
