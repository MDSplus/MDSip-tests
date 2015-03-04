
#include "DataUtils.h"
#include "testing-prototype.h"


int main(int argc, char *argv[])
{
    BEGIN_TESTING(Data Utils);


    ////////////////////////////////////////////////////////////////////////////////
    //  are_same  //////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    {
        float f = 1.1E-5;
        TEST1_P( are_same(f,(float)1.1E-5) );
        TEST0_P( are_same(f,(float)1.2E-5) );
    }

    { // TEST TUPLE FLOAT //
        Vector4f v4f;
        TEST1_P( AreSame<float>(v4f(0),0) );
        TEST1_P( AreSame<float>(v4f(1),0) );
        TEST1_P( AreSame<float>(v4f(2),0) );
        TEST1_P( AreSame<float>(v4f(3),0) );

        v4f << 0,1,2,3;
        TEST1_P( AreSame<float>(v4f(0),0) );
        TEST1_P( AreSame<float>(v4f(1),1) );
        TEST1_P( AreSame<float>(v4f(2),2) );
        TEST1_P( AreSame<float>(v4f(3),3) );

        Vector4i v4i = v4f.cast<int>();
        TEST1_P( v4i(0) == static_cast<int>(v4f(0)) );
        TEST1_P( v4i(1) == static_cast<int>(v4f(1)) );
        TEST1_P( v4i(2) == static_cast<int>(v4f(2)) );
        TEST1_P( v4i(3) == static_cast<int>(v4f(3)) );

        Vector4f v1,v2;
        v1 << 0,1,2,3;
        v2 << 1,2,3,4;
        TEST1_P( v1 < v2 && !(v2 < v1));

        std::vector<Vector4f> v;
        v.push_back(v2);
        v.push_back(v1);
        TEST1_P( *std::min_element(v.begin(),v.end()) == v1 );
        TEST0_P( *std::min_element(v.begin(),v.end()) == v2 );



    }


    { // FILL PLOT and PRINT OUT TO GNUPLOT FORMAT //
        Curve2D curve1("curve1"), curve2("curve2"), curve3("curve3");
        for(int i=0; i<10; ++i) {
            Curve2D::Point pt;
            double x = static_cast<double>(i)/10;
            pt << x, sin(x), sin(x)/3;
            curve1.AddPoint(pt);
            curve2.AddPoint( Curve2D::Point(x, sin(x)/2 + (static_cast<float>(rand()) / RAND_MAX - 0.5) * 0.1, 0));
            curve3.AddPoint( Curve2D::Point(x*2, sin(x), 0));
        }

        curve1.Update();
        curve2.Update();
        curve3.Update();

        Plot2D plot("Test plot");
        plot.AddCurve(curve1);
        plot.AddCurve(curve2);
        plot.AddCurve(curve3);

        plot.XAxis() = curve1.XAxis();
        plot.XAxis().name = "X-Axis";
        plot.YAxis() = curve1.YAxis();
        plot.YAxis().name = "Y-Axis";

        std::ofstream fout;
        fout.open("test_gnuplot.csv");
        plot.PrintToCsv(fout);
        fout.close();

        plot.PrintToGnuplotFile();

    }


    { // HISTOGRAMS //

        Histogram<double> h("test",20,-5,5);
        for (int i=0; i<5000; ++i) {
            h << StatisticGen::boxMuller(0,1);
        }
        Curve2D curve = h;

        foreach (Point2D &pt, curve.Points()) {
            pt(1) /= h.Size();
            pt(2) = StatisticGen::noiseWhite() / 10;
        }

        Plot2D plot("test histogram");

        plot.AddCurve(curve);
        plot.CurveFlags(0) = Plot2D::ShowPoints | Plot2D::ShowLines;

        plot.PrintToGnuplotFile("test_histogram");
    }



    END_TESTING;
}

