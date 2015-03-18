set terminal postscript eps enhanced color font 'Helvetica,20' 
set output 'content-tcp.eps' 
set style line 1 lc rgb '#104e8b' lt 1 lw 4 pt 7 ps 1.3
set style line 2 lc rgb '#cd5c5c' lt 1 lw 4 pt 7 ps 1.3
set style line 3 lc rgb '#388e8e' lt 1 lw 4 pt 7 ps 1.3
set key below 
set grid 
set title "Content Throughput vs Segment Size in tcp\n{/*0.5 (local time: 2015-03-17.19:20:05) eprobe.rfx.local  -->  test10g.nifs.ac.jp}" font 'Helvetica,25' 
set xlabel 'Segment size [KB] of signal data' 
set ylabel 'Total speed [MB/s]' 
plot "content-tcp.dat" index 0 using 1:2:3  title "sine" w yerrorbars ls 1 , \
  '' index 0 using 1:2:3 smooth acsplines notitle w lines ls 1, \
  '' index 1 using 1:2:3  title "noiseW" w yerrorbars ls 2 , \
  '' index 1 using 1:2:3 smooth acsplines notitle w lines ls 2, \
  '' index 2 using 1:2:3  title "noiseG" w yerrorbars ls 3 , \
  '' index 2 using 1:2:3 smooth acsplines notitle w lines ls 3
