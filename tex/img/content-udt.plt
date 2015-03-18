set terminal postscript eps enhanced color font 'Helvetica,20' 
set output 'content-udt.eps' 
set style line 1 lc rgb '#104e8b' lt 1 lw 4 pt 7 ps 1.3
set style line 2 lc rgb '#cd5c5c' lt 1 lw 4 pt 7 ps 1.3
set style line 3 lc rgb '#388e8e' lt 1 lw 4 pt 7 ps 1.3
set key below 
set grid 
set title "Content Throughput vs Segment Size in udt\n{/*0.5 (local time: 2015-03-17.18:26:14) eprobe.rfx.local  -->  test10g.nifs.ac.jp}" font 'Helvetica,25' 
set xlabel 'Segment size [MB] of signal data' 
set ylabel 'Total speed [MB/s]' 
plot "content-udt.dat" index 0 using ($1/1000):2:3  title "sine" w yerrorbars ls 1 , \
  '' index 0 using ($1/1000):2:3 smooth acsplines notitle w lines ls 1, \
  '' index 1 using ($1/1000):2:3  title "noiseW" w yerrorbars ls 2 , \
  '' index 1 using ($1/1000):2:3 smooth acsplines notitle w lines ls 2, \
  '' index 2 using ($1/1000):2:3  title "noiseG" w yerrorbars ls 3 , \
  '' index 2 using ($1/1000):2:3 smooth acsplines notitle w lines ls 3
