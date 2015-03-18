set terminal postscript eps enhanced color font 'Helvetica,20' 
set output 'distr-udt-speed.eps' 
set style line 1 lc rgb '#104e8b' lt 1 lw 4 pt 7 ps 1.3
set style line 2 lc rgb '#cd5c5c' lt 1 lw 4 pt 7 ps 1.3
set style line 3 lc rgb '#388e8e' lt 1 lw 4 pt 7 ps 1.3
set key below 
set grid 
set title "Speed Distribution in udt segsize = 20480 [KB]\n{/*0.5 (local time: 2015-03-17.19:03:18) eprobe.rfx.local  -->  test10g.nifs.ac.jp}" font 'Helvetica,25' 
set xlabel 'Transmission speed [MB/s]' 
set ylabel 'Transmission probability' 
plot "distr-udt-speed.dat" index 0 using 1:2:3 title  "ch1"  w lines ls 1, \
  '' index 1 using 1:2:3 title  "ch2"  w lines ls 2, \
  '' index 2 using 1:2:3 title  "ch3"  w lines ls 3
