set terminal postscript eps enhanced color font 'Helvetica,20' 
set output 'distr-tcp-time.eps' 
set style line 1 lc rgb '#104e8b' lt 1 lw 4 pt 7 ps 1.3
set style line 2 lc rgb '#cd5c5c' lt 1 lw 4 pt 7 ps 1.3
set key below 
set grid 
set title "Time Distribution in tcp segsize = 40 [KB]\n{/*0.5 (local time: 2015-03-17.08:47:54) eprobe.rfx.local  -->  test10g.nifs.ac.jp}" font 'Helvetica,25' 
set xlabel 'Transmission time [s]' 
set ylabel 'Transmission probability' 
plot "distr-tcp-time.dat" index 0 using 1:2:3 title  "ch1"  w lines ls 1, \
  '' index 1 using 1:2:3 title  "ch8"  w lines ls 2
