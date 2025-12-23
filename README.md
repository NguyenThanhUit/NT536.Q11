# NT536.Q11
Cách dùng:

sudo /usr/local/nginx/sbin/nginx -t
sudo /usr/local/nginx/sbin/nginx

sudo nano /usr/local/nginx/conf/nginx.conf

sudo gedit /usr/local/nginx/conf/nginx.conf

#Tạo thư mục
sudo mkdir -p /tmp/live/hls
sudo chmod -R 755 /tmp/live
sudo chown -R nginx:nginx /tmp/live
sudo mkdir -p /tmp/hls
sudo chown -R nginx:nginx /tmp/hls
sudo chmod -R 755 /tmp/hls
sudo pkill nginx
sudo /usr/local/nginx/sbin/nginx


#recording
sudo mkdir -p /var/recordings
sudo chown -R nginx:nginx /var/www/html/recordings-flv
sudo chmod -R 755 /var/www/html/recordings-flv
sudo chown -R nginx:nginx /var/www/html/recordings-mp4
sudo chmod -R 755 /var/www/html/recordings-mp4
sudo chown -R nginx:nginx /var/www/html/vods-hls
sudo chmod -R 755 /var/www/html/vods-hls


#Script convert frv sang mp4
/usr/local/bin/convert_recordings.sh
sudo chmod +x /usr/local/bin/convert_recordings.sh

#Script convert mp4 sang flv
/usr/local/bin/mp4_to_hls.sh
sudo chmod +x /usr/local/bin/mp4_to_hls.sh
# Edit crontab
sudo crontab -e


*/1 * * * * /usr/local/bin/convert_recordings.sh >> /var/log/convert_recordings.log 2>&1


ffmpeg ^
-f dshow -rtbufsize 512M ^
-i video="Integrated Camera":audio="Microphone Array (Intel® Smart Sound Technology for Digital Microphones)" ^
-vf format=yuv420p ^
-c:v libx264 -preset veryfast -tune zerolatency ^
-profile:v baseline -level 3.1 ^
-b:v 2000k -maxrate 2000k -bufsize 4000k ^
-g 60 -keyint_min 60 ^
-c:a aac -b:a 128k ^
-f flv rtmp://192.168.39.181:1935/live/camera1



