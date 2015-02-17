
#include <stdlib.h>
#include <math.h>

#include "StatisticsUtils.h"


double StatisticGen::boxMuller(const double mean, const double sigma)
{
    //    static const double mean = 0;
    //    static const double sigma = 1;

    float x1, x2, w, y1;
    static double y2;
    static int use_last = 0;

    if (use_last)
    {
        y1 = y2;
        use_last = 0;
    }
    else
    {
        do {
            x1 = 2.0 * (double)rand() / RAND_MAX - 1.0;
            x2 = 2.0 * (double)rand() / RAND_MAX - 1.0;
            w = x1 * x1 + x2 * x2;
        } while ( w >= 1.0 );

        w = sqrt( (-2.0 * log( w ) ) / w );
        y1 = x1 * w;
        y2 = x2 * w;
        use_last = 1;
    }
    return( mean + y1 * sigma );
}


double StatisticGen::noiseWhite()
{
    return (double)rand() / RAND_MAX;
}
