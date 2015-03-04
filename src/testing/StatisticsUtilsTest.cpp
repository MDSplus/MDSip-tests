
#include "ClassUtils.h"
#include "StatisticsUtils.h"

#include "testing-prototype.h"


typedef float Scalar;

static Scalar test_dummy_mean(const std::vector<Scalar> &v) {
    Scalar acc = 0;
    foreach (Scalar val, v) {
        acc += val;
    }
    return acc / v.size();
}


static Scalar test_kahan_mean(const std::vector<Scalar> &v) {
    detail::mean_kahan<Scalar> mean;
    foreach (Scalar val, v) {
        mean << val;
    }
    return mean();
}


static Scalar test_dummy_variance(const std::vector<Scalar> &v) {
    Scalar mean = test_dummy_mean(v);
    Scalar variance = 0;
    foreach (Scalar val, v) {
        variance += pow(val-mean,2);
    }
    return variance / v.size();
}



int main(int argc, char *argv[])
{
    BEGIN_TESTING(Statistics Utils);

    { // TEST INCREMENTAL VARIANCE //
        std::vector<Scalar> data;
        StatUtils::IncrementalOrder2 st;
        int n = 0;
        do {
            Scalar val = StatisticGen::boxMuller(0,1);
            data.push_back(val);
            st.add(val);
            ++n;
            if(n > 50) break; // safe exit //
        } while( n==1 || fabs(sqrt(test_dummy_variance(data))-sqrt(st.variance())) > 0.1 );

        // test that incremental variance error is less than 10% for at least 5 samples //
        TEST1_P( n <= 5 );
    }



    END_TESTING;
}
